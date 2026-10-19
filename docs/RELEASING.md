# 版本发布 / Release distribution

源码与正式版本主入口位于[ecjtu-tools-pro](https://github.com/ADCharles/ecjtu-tools-pro)。[ecjtu-tools-pro-releases](https://github.com/ADCharles/ecjtu-tools-pro-releases)继续提供分发兼容入口。

正式版本使用`v主版本.次版本.修订版本`标签，在GitHub Releases上传相应平台的安装包、更新元数据和摘要文件。

两个仓库每15分钟检查一次版本同步，实际执行时间取决于GitHub Actions调度。新仓库是同名已发布版本的主来源；新仓库会补入旧分发仓库新增的版本。两端的Actions页面均支持手动运行。

同步按安装包文件名、大小和SHA-256验证。公告属于独立发布配置，版本同步工具只处理版本标签。每个仓库的任务使用其自身的临时`GITHUB_TOKEN`，不需要保存跨仓库个人令牌。

需要立即同步时，可使用对目标仓库有写权限的临时`GH_TOKEN`：

```sh
python tools/sync_releases.py \
  --source ADCharles/ecjtu-tools-pro \
  --target ADCharles/ecjtu-tools-pro-releases \
  --tag v4.1.0 --apply
```

省略`--apply`将列出计划。`--missing-only`只补入目标中尚未正式发布的版本。

## English

[ecjtu-tools-pro](https://github.com/ADCharles/ecjtu-tools-pro) hosts source and canonical releases. [ecjtu-tools-pro-releases](https://github.com/ADCharles/ecjtu-tools-pro-releases) remains a compatible distribution endpoint.

Publish version tags in the form `vMAJOR.MINOR.PATCH`, with installers, update manifests and checksums attached to the corresponding GitHub Release.

Both repositories check for release updates every 15 minutes, subject to GitHub Actions scheduling. The source repository is authoritative for an already-published version; it also imports versions first published in the distribution repository. Both workflows support manual dispatch.

Assets are checked by file name, size and SHA-256. The mirror handles version tags only; application notices are managed separately. Each workflow uses its own repository's ephemeral `GITHUB_TOKEN`, without a stored cross-repository personal token.

The command above performs immediate synchronization for one version. Omit `--apply` for a plan, or use `--missing-only` to import versions that have not yet been published in the target.
