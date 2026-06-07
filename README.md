# base_image

这个仓库用于维护常用基础镜像，重点解决老版本发行版在归档源、阿里云镜像源以及多架构发布上的可用性问题。

当前镜像统一发布为多架构 manifest，`linux/amd64` 和 `linux/arm64` 共用同一个 tag。

## 镜像列表

| 系统 | Dockerfile | 说明 | 发布标签 |
| --- | --- | --- | --- |
| CentOS 7 | `centos/aliyun/Dockerfile` | 将 CentOS 7、EPEL、SCL 源切换到阿里云可用归档源 | `ghcr.io/zarraxx/centos:aliyun` |
| CentOS 7 + devtoolset-10 | `centos/devtoolset/Dockerfile` | 在 CentOS 7 阿里云源基础上安装 `devtoolset-10` 和常见构建依赖 | `ghcr.io/zarraxx/centos:devtoolset10` |
| Debian 10 | `debian/10/aliyun/Dockerfile` | 从 `archive.debian.org` 引导后切换到阿里云 Debian Archive 源 | `ghcr.io/zarraxx/debian:10-aliyun` |

## 目录结构

```text
.
├── centos
│   ├── aliyun
│   │   └── Dockerfile
│   └── devtoolset
│       └── Dockerfile
└── debian
    └── 10
        └── aliyun
            └── Dockerfile
```

## 本地构建

在仓库根目录执行：

```bash
docker build -f centos/aliyun/Dockerfile -t local/centos:aliyun .
docker build -f centos/devtoolset/Dockerfile -t local/centos:devtoolset10 .
docker build -f debian/10/aliyun/Dockerfile -t local/debian:10-aliyun .
```

如果你本地使用的是 `podman`，也可以参考仓库内的 `build.sh` 脚本做单镜像构建。

## GitHub Actions 发布

仓库已约定使用 GitHub Container Registry（GHCR）发布镜像，workflow 会构建并推送以下 tag：

```text
ghcr.io/zarraxx/centos:aliyun
ghcr.io/zarraxx/centos:devtoolset10
ghcr.io/zarraxx/debian:10-aliyun
```

### 触发方式

- 推送到 `main` 或 `master`，且变更涉及 `centos/**`、`debian/**` 或 workflow 文件时自动发布
- 发起 Pull Request 时自动执行构建校验，但不会推送镜像
- 支持在 GitHub Actions 页面手动触发，并选择构建全部或单个镜像

### Secrets

需要在仓库 `Settings > Secrets and variables > Actions` 中配置：

- `GH_KEY`：具备 `write:packages` 权限的 GitHub Personal Access Token，用于登录 GHCR

## 说明

- `centos/*` 下的 Dockerfile 当前依赖上游基础镜像 `ghcr.io/zarraxx/centos:centos7`
- 如后续新增镜像，按现有目录结构补充 Dockerfile，并同步更新 workflow 的 matrix 即可
