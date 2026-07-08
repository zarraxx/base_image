# AGENTS.md

本文件给后续在本仓库工作的 Codex/自动化代理使用。除非用户明确要求跳过，这些约定都应遵守。

## 工作范围

- 本仓库维护基础容器镜像、rootfs 构建脚本、GitHub Actions 发布流程，以及 Debian loong64 netinst ISO 重打包流程。
- 优先保持现有目录结构、命名风格和脚本入口，不要为小改动引入新的抽象或工具链。
- 变更要聚焦在用户请求涉及的镜像、脚本或 workflow，避免顺手重构无关内容。

## 提交前必须检查

每次提交前必须执行一次代码回顾，并根据回顾结果更新文档：

1. 查看 `git diff`，确认实际变更与用户请求一致。
2. 检查是否修改了镜像内容、构建参数、发布 tag、workflow 触发条件、secret、测试方式或目录结构。
3. 如果以上任一内容发生变化，必须同步更新 `README.md`。
4. 即使认为 README 不需要变化，也要在提交前明确做过这个判断。

推荐检查命令：

```bash
git diff --check
git diff -- README.md AGENTS.md .github/workflows
git status --short
```

## 验证要求

- Dockerfile 或 build 脚本变化后，优先运行对应目录的 `build.sh` / `test.sh`；如果本地环境不满足条件，要在最终说明中写清楚未运行原因。
- workflow 变化后，检查 YAML 结构、触发路径、镜像 tag、secret 名称和发布 registry 是否一致。
- rootfs、loong64、Darling、osxcross 等依赖特权容器、QEMU/binfmt 或外部下载的流程，允许只做静态检查，但必须说明限制。

## 文档同步重点

修改以下内容时，通常需要更新 `README.md`：

- 新增、删除或重命名镜像
- 发布 registry、repository、tag 或 manifest 架构变化
- GitHub Actions workflow、触发条件、matrix 或 secret 变化
- 构建脚本参数、默认值或依赖变化
- 目录结构变化
- ISO 重打包输入、输出、校验方式或 release tag 变化

## 安全边界

- 不要删除或回滚用户已有改动，除非用户明确要求。
- 不要提交凭据、token、私有 registry 密码或本地生成的大文件。
- 避免使用破坏性 Git 命令；确需使用时先取得用户明确同意。
