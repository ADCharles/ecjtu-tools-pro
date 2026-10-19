# Copyright (c) 2026 阿东Charles (ADCharles).
# SPDX-License-Identifier: GPL-3.0-only
# See LICENSE-ADDITIONAL.md for additional terms.
import unittest
from unittest.mock import Mock, patch
from urllib.request import Request

from sync_releases import SafeRedirects, VERSION_TAG, sync, version_key


class ReleaseSyncTests(unittest.TestCase):
    def test_version_tags_include_semantic_versions(self):
        for tag in ['v4.0.1', 'v4.1.0', 'v4.1.0-rc.1']:
            self.assertIsNotNone(VERSION_TAG.fullmatch(tag))

    def test_notice_generations_are_never_version_releases(self):
        for tag in ['app-notices', 'app-notices-v2', 'app-notices-dev', 'app-notices-test']:
            self.assertIsNone(VERSION_TAG.fullmatch(tag))

    def test_numeric_version_order(self):
        releases = [{'tag_name':t} for t in ['v4.1.0', 'v4.10.0', 'v4.2.0']]
        self.assertEqual([r['tag_name'] for r in sorted(releases,key=version_key)],
                         ['v4.1.0','v4.2.0','v4.10.0'])

    def test_signed_asset_redirect_drops_authorization(self):
        request = Request('https://api.github.com/repos/a/b/releases/assets/1',
                          headers={'Authorization':'Bearer example'})
        redirected = SafeRedirects().redirect_request(request, None, 302, 'Found', {},
                         'https://release-assets.githubusercontent.com/example')
        self.assertIsNone(redirected.get_header('Authorization'))

    def test_untrusted_asset_redirect_is_rejected(self):
        with self.assertRaises(ValueError):
            SafeRedirects().redirect_request(Request('https://github.com/a/b'), None, 302,
                                            'Found', {}, 'https://example.net/file')

    def test_same_repository_is_rejected(self):
        with self.assertRaises(ValueError):
            sync('a/b','A/B',None)

    def test_missing_only_preserves_existing_published_target(self):
        source={'tag_name':'v4.1.0','draft':False,'prerelease':False,'assets':[]}
        target={**source,'body':'target metadata'}
        client=Mock()
        client.releases.side_effect=[[source],[target]]
        with patch('sync_releases.GitHub',return_value=client):
            sync('a/source','a/target','example',True,missing_only=True)
        client.request.assert_not_called()


if __name__=='__main__':
    unittest.main()
