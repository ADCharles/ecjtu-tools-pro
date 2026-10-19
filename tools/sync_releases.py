#!/usr/bin/env python3
# Copyright (c) 2026 阿东Charles (ADCharles).
# SPDX-License-Identifier: GPL-3.0-only
# See LICENSE-ADDITIONAL.md for additional terms.
"""Mirror published version releases while keeping application notices separate."""
import argparse
import hashlib
import json
import os
import re
import tempfile
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener

VERSION_TAG = re.compile(r'^v(\d+)\.(\d+)\.(\d+)(?:[-+][A-Za-z0-9_.-]+)?$')
REPOSITORY = re.compile(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')
DOWNLOAD_HOSTS = {'api.github.com', 'github.com',
                  'release-assets.githubusercontent.com', 'objects.githubusercontent.com'}


class SafeRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        uri = urlparse(newurl)
        if uri.scheme != 'https' or uri.hostname not in DOWNLOAD_HOSTS:
            raise ValueError('Unexpected download redirect host')
        redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
        if uri.hostname != urlparse(req.full_url).hostname:
            redirected.remove_header('Authorization')
        return redirected


class GitHub:
    def __init__(self, token):
        self.token = token
        self.opener = build_opener(SafeRedirects())

    def request(self, url, method='GET', body=None, content_type=None):
        if not url.startswith('https://api.github.com/') and not url.startswith('https://uploads.github.com/'):
            raise ValueError('Unexpected GitHub API host')
        headers = {'User-Agent': 'ECJTU-Release-Sync', 'Accept': 'application/vnd.github+json',
                   'X-GitHub-Api-Version': '2022-11-28'}
        if self.token:
            headers['Authorization'] = 'Bearer '+self.token
        if isinstance(body, dict):
            body = json.dumps(body, ensure_ascii=False).encode('utf-8')
            content_type = 'application/json; charset=utf-8'
        if content_type:
            headers['Content-Type'] = content_type
        for attempt in range(3):
            try:
                with self.opener.open(Request(url, data=body, headers=headers, method=method), timeout=180) as response:
                    raw = response.read()
                    return json.loads(raw) if raw else None
            except HTTPError as error:
                if error.code < 500 or method != 'GET' or attempt == 2:
                    raise
            except (URLError, TimeoutError, OSError):
                if method != 'GET' or attempt == 2:
                    raise
            time.sleep(2 ** attempt)

    def releases(self, repo):
        result = []
        for page in range(1, 101):
            batch = self.request(f'https://api.github.com/repos/{repo}/releases?per_page=100&page={page}')
            result.extend(batch)
            if len(batch) < 100:
                return result
        raise RuntimeError('Release pagination limit reached')

    def download(self, url, destination):
        uri = urlparse(url)
        if uri.scheme != 'https' or uri.hostname not in DOWNLOAD_HOSTS:
            raise ValueError('Unexpected asset download host')
        # Browser download URLs are public. No API credential is attached here.
        request = Request(url, headers={'User-Agent': 'ECJTU-Release-Sync'})
        digest, size = hashlib.sha256(), 0
        with self.opener.open(request, timeout=180) as response, destination.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
                digest.update(chunk)
                size += len(chunk)
        return 'sha256:'+digest.hexdigest(), size


def version_key(release):
    match = VERSION_TAG.fullmatch(release['tag_name'])
    return tuple(map(int, match.groups())) + (not release.get('prerelease', False),)


def sync(source, target, token, apply=False, only_tag=None, missing_only=False):
    if not REPOSITORY.fullmatch(source) or not REPOSITORY.fullmatch(target) or source.lower() == target.lower():
        raise ValueError('Supply two distinct owner/repository names')
    if apply and not token:
        raise ValueError('GH_TOKEN is required for --apply')
    if only_tag and not VERSION_TAG.fullmatch(only_tag):
        raise ValueError('--tag must be a version tag')
    github = GitHub(token)
    releases = sorted((r for r in github.releases(source) if not r['draft'] and VERSION_TAG.fullmatch(r['tag_name'])
                       and (not only_tag or r['tag_name'] == only_tag)), key=version_key)
    if only_tag and not releases:
        raise ValueError('Requested published source version was not found')
    existing = {r['tag_name']:r for r in github.releases(target)}
    for release in releases:
        tag = release['tag_name']
        current = existing.get(tag)
        if missing_only and current is not None and not current['draft']:
            continue
        print(f'{source} -> {target}: {tag}, {len(release["assets"])} assets', flush=True)
        if not apply:
            continue
        created = current is None
        if created:
            current = github.request(f'https://api.github.com/repos/{target}/releases', 'POST', {
                'tag_name': tag, 'name': release['name'] or tag, 'body': release.get('body') or '',
                'draft': True, 'prerelease': release['prerelease'], 'make_latest': 'false'})
        assets = {a['name']:a for a in current['assets']}
        for asset in release['assets']:
            name = asset['name']
            if Path(name).name != name or name in {'.', '..'} or '/' in name or '\\' in name:
                raise ValueError('Unsafe asset name')
            previous = assets.get(name)
            if previous and asset.get('digest') and previous.get('digest') == asset['digest'] and previous['size'] == asset['size']:
                continue
            with tempfile.TemporaryDirectory(prefix='ecjtu-release-sync-') as directory:
                file = Path(directory)/'asset'
                digest, size = github.download(asset['browser_download_url'], file)
                if size != asset['size'] or (asset.get('digest') and digest != asset['digest']):
                    raise RuntimeError('Source asset integrity check failed: '+name)
                if previous and previous.get('digest') == digest and previous['size'] == size:
                    continue
                pending_name = name+'.sync-'+digest[-12:]
                pending = assets.get(pending_name)
                if pending and pending.get('digest') == digest and pending['size'] == size:
                    uploaded = pending
                else:
                    if pending:
                        raise RuntimeError('Conflicting incomplete asset: '+pending_name)
                    upload = current['upload_url'].split('{',1)[0]+'?name='+quote(pending_name, safe='')
                    uploaded = github.request(upload, 'POST', file.read_bytes(), 'application/octet-stream')
                if uploaded.get('digest') != digest or uploaded['size'] != size:
                    raise RuntimeError('Uploaded asset integrity check failed: '+name)
                if previous:
                    github.request(f'https://api.github.com/repos/{target}/releases/assets/{previous["id"]}', 'DELETE')
                uploaded = github.request(f'https://api.github.com/repos/{target}/releases/assets/{uploaded["id"]}',
                                          'PATCH', {'name':name, 'label':asset.get('label') or ''})
                assets[name] = uploaded
                print(f'  verified {name}: {size} bytes', flush=True)
        github.request(f'https://api.github.com/repos/{target}/releases/{current["id"]}', 'PATCH', {
            'name':release['name'] or tag, 'body':release.get('body') or '', 'draft':False,
            'prerelease':release['prerelease'], 'make_latest':'false' if release['prerelease'] else 'true'})
        verified = github.request(f'https://api.github.com/repos/{target}/releases/tags/{quote(tag,safe="")}')
        verified_assets = {a['name']:a for a in verified['assets']}
        for original in release['assets']:
            copied = verified_assets.get(original['name'])
            if not copied or copied['size'] != original['size'] or (original.get('digest') and copied.get('digest') != original['digest']):
                raise RuntimeError('Final release verification failed: '+tag)
        print('  published and verified '+tag, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True)
    parser.add_argument('--target', required=True)
    parser.add_argument('--tag')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--missing-only', action='store_true', help='Import only versions not yet published in the target')
    args = parser.parse_args()
    sync(args.source, args.target, os.environ.get('GH_TOKEN'), args.apply, args.tag, args.missing_only)
