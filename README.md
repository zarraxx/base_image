# base_image

这个仓库维护常用基础镜像和少量发行版安装介质重打包流程，重点解决旧发行版归档源、多架构镜像、交叉编译工具链和 LoongArch/loong64 可用性问题。

镜像主要发布到 GitHub Container Registry（GHCR）和阿里云容器镜像服务。GitHub Actions 会在推送到 `main` / `master`、相关目录变更或手动触发时执行构建；Pull Request 只做构建和测试校验，不推送镜像。

## 镜像列表

| 类型 | Dockerfile / 构建入口 | 说明 | 发布标签 |
| --- | --- | --- | --- |
| CentOS 7 | `centos/aliyun/Dockerfile` | 将 CentOS 7、EPEL、SCL 源切换到可用归档源 | `ghcr.io/zarraxx/centos:aliyun` |
| CentOS 7 + devtoolset-10 | `centos/devtoolset/Dockerfile` | CentOS 7 归档源基础上安装 GCC 10、binutils 和常见构建依赖 | `ghcr.io/zarraxx/centos:devtoolset10` |
| Debian 10 Aliyun | `debian/10/aliyun/Dockerfile` | Debian 10 归档源引导后切换到阿里云 Debian Archive | `ghcr.io/zarraxx/debian:10-aliyun` |
| Debian 10 rootfs | `debian/10/rootfs/build.sh` | 使用 `debootstrap` 从 `archive.debian.org` 生成多架构 Buster rootfs 镜像 | `ghcr.io/zarraxx/debian:10`、`ghcr.io/zarraxx/debian:buster` |
| Debian 12 rootfs | `debian/12/rootfs/build.sh` | 使用 `debootstrap` 生成 Debian Bookworm 全架构 rootfs 镜像 | `ghcr.io/zarraxx/debian:12`、`ghcr.io/zarraxx/debian:bookworm` |
| Debian 13 | `debian/13/Dockerfile` | Debian Trixie 基础构建工具镜像 | `ghcr.io/zarraxx/debian:13`、`ghcr.io/zarraxx/debian:trixie` |
| Debian 13 loong64 | `debian/13/loong64/build.sh` | 使用非官方 Debian loong64 源生成 Trixie loong64 rootfs 镜像 | 合并到 `ghcr.io/zarraxx/debian:13`、`ghcr.io/zarraxx/debian:trixie` manifest |
| Loong64 OpenJDK Debian 包 | `openjdk/loong64/build.sh` | 将 Loongnix 官方 OpenJDK loongarch64 tarball 重打包为 Debian loong64 `.deb` | `openjdk-8-jdk`、`openjdk-11-jdk`、`openjdk-17-jdk`、`openjdk-21-jdk`、`openjdk-25-jdk` |
| OpenJDK | `openjdk/Dockerfile`、`openjdk/loong64` | 构建 OpenJDK 8/11/17/21/25 多架构镜像，并发布 loong64 Debian 包 | `ghcr.io/zarraxx/openjdk:<version>`、`ghcr.io/zarraxx/openjdk:<version>-loong64` |
| Wine | `debian/12/wine/Dockerfile` | Debian 12 上的 Wine、wine32/wine64 和 Chromium `depot_tools` 环境 | `ghcr.io/zarraxx/wine:debian-12` |
| Wine + MSVC | `debian/12/wine-msvc/Dockerfile` | 基于 Wine 镜像安装 `msvc-wine`、MSVC 和 Windows SDK | `registry.cn-hangzhou.aliyuncs.com/zarra/wine:msvc` |
| Darling | `ubuntu/24.04/darling/Dockerfile` | Ubuntu 24.04 上安装 Darling deb 包，用于运行 macOS 用户态程序 | `ghcr.io/zarraxx/darling:noble-20260608` |
| osxcross | `ubuntu/24.04/osxcross/Dockerfile` | Ubuntu 24.04 上构建 osxcross macOS 交叉编译工具链 | `registry.cn-hangzhou.aliyuncs.com/zarra/osxcross:MacOSX11.3` |

## 多架构标签

`build-images.yml` 构建的 CentOS 和 `debian:10-aliyun` 镜像发布为 `linux/amd64`、`linux/arm64` 多架构 manifest。

`debian-10.yml` 生成并发布以下架构标签，再合并为 `debian:10` 和 `debian:buster`：

```text
buster-amd64
buster-armv7
buster-aarch64
buster-mips64el
buster-ppc64el
buster-s390x
```

`debian-12.yml` 生成并发布以下架构标签，再合并为 `debian:12` 和 `debian:bookworm`：

```text
bookworm-amd64
bookworm-i386
bookworm-armel
bookworm-armv7
bookworm-aarch64
bookworm-mipsel
bookworm-mips64el
bookworm-ppc64el
bookworm-s390x
```

`build-debian-13.yml` 生成并发布以下架构标签，再合并为 `debian:13` 和 `debian:trixie`：

```text
trixie-amd64
trixie-arm32v7
trixie-arm64v8
trixie-ppc64le
trixie-riscv64
trixie-s390x
trixie-loong64
```

`build-openjdk.yml` 按 Debian 仓库中实际可用的 OpenJDK 版本构建临时架构标签，再合并为 `openjdk:<version>`：

| OpenJDK | Debian 基座 | 额外 apt 源 | 发布架构标签 |
| --- | --- | --- | --- |
| 8 | Debian 10 Buster | Debian 9 Stretch archive main/security | `8-amd64`、`8-aarch64`、`8-ppc64le`、`8-s390x`、`8-mips64le`、`8-loong64` |
| 11 | Debian 10 Buster | 无 | `11-amd64`、`11-aarch64`、`11-ppc64le`、`11-s390x`、`11-mips64le`、`11-loong64` |
| 17 | Debian 12 Bookworm | 无 | `17-amd64`、`17-aarch64`、`17-ppc64le`、`17-s390x`、`17-mips64le`、`17-loong64` |
| 21 | Debian 13 Trixie | 无 | `21-amd64`、`21-aarch64`、`21-ppc64le`、`21-riscv64`、`21-s390x`、`21-loong64` |
| 25 | Debian 13 Trixie | 无 | `25-amd64`、`25-aarch64`、`25-ppc64le`、`25-riscv64`、`25-s390x`、`25-loong64` |

`riscv64` 只发布 Debian 13 上可用的 OpenJDK 21/25；`mips64le` 只发布 Debian 10/12 上可用的 OpenJDK 8/11/17。LoongArch/loong64 会先单独构建 `openjdk:<version>-loong64`，再合并到 `openjdk:<version>` manifest，并把生成的 `openjdk-*-jdk_*_loong64.deb` 上传到 GitHub Release `loong64-openjdk-debs`。

## Loong64 Netinst ISO

`release-loong64-netinst-iso.yml` 用于重打包 Debian loong64 netinst ISO，默认输入为 Debian `13.5.0`：

- 从官方 loong64 netinst ISO 下载源文件
- 重打包为 GPT + protective MBR
- 追加 14 MiB FAT16 EFI System Partition
- 添加大写 LoongArch UEFI fallback 文件名：
  - `EFI/BOOT/BOOTLOONGARCH64.EFI`
  - `EFI/BOOT/BOOTLOONGARCH.EFI`
- 上传 ISO、SHA256 和校验日志到 GitHub Release

触发方式：

- 推送匹配 `loong64-netinst-*` 的 tag
- 在 GitHub Actions 手动触发，并填写 `version`、`source_iso_url`、`release_tag`

默认 release tag：

```text
loong64-netinst-13.5.0-gpt-esp
```

## 目录结构

```text
.
├── centos
│   ├── aliyun
│   └── devtoolset
├── debian
│   ├── 10
│   │   ├── aliyun
│   │   └── rootfs
│   ├── 12
│   │   ├── rootfs
│   │   ├── wine
│   │   └── wine-msvc
│   └── 13
│       └── loong64
├── openjdk
│   └── loong64
├── ubuntu
│   └── 24.04
│       ├── darling
│       └── osxcross
└── .github
    └── workflows
```

## 本地构建

常规 Dockerfile 可直接构建：

```bash
docker build -f centos/aliyun/Dockerfile -t local/centos:aliyun .
docker build -f centos/devtoolset/Dockerfile -t local/centos:devtoolset10 .
docker build -f debian/10/aliyun/Dockerfile -t local/debian:10-aliyun .
docker build -f debian/13/Dockerfile -t local/debian:trixie .
```

带脚本的镜像建议进入对应目录执行：

```bash
cd debian/12/wine && ./build.sh && ./test.sh
cd debian/12/wine-msvc && ./build.sh && ./test.sh
cd ubuntu/24.04/darling && ./build.sh && ./test.sh
cd ubuntu/24.04/osxcross && ./build.sh 11.3 && ./test.sh osxcross:MacOSX11.3
```

rootfs 类构建需要 `sudo`、`debootstrap`、QEMU/binfmt 和 Docker 或 Podman：

```bash
cd debian/10/rootfs
CONTAINER_TOOL=docker DEBIAN_ARCH=amd64 PLATFORM=linux/amd64 SUFFIX=amd64 IMAGE_TAG=localhost/debian:buster-amd64 ./build.sh

cd ../../12/rootfs
CONTAINER_TOOL=docker DEBIAN_ARCH=amd64 PLATFORM=linux/amd64 SUFFIX=amd64 IMAGE_TAG=localhost/debian:bookworm-amd64 ./build.sh

cd ../../13/loong64
CONTAINER_TOOL=docker ./build.sh
```

loong64 OpenJDK `.deb` 打包：

```bash
cd openjdk/loong64
./build.sh
./test.sh
```

部分构建脚本会清理 dangling image，并删除同名本地镜像后重新构建。

## GitHub Actions

| Workflow | 作用 | 主要触发路径 |
| --- | --- | --- |
| `build-images.yml` | CentOS、CentOS devtoolset、Debian 10 Aliyun 多架构镜像 | `centos/**`、`debian/10/aliyun/**` |
| `debian-10.yml` | Debian 10 rootfs 多架构镜像和 manifest | `debian/10/**` |
| `debian-12.yml` | Debian 12 rootfs 全架构镜像和 manifest | `debian/12/rootfs/**` |
| `build-debian-13.yml` | Debian 13 官方架构、loong64 镜像和 manifest | `debian/13/**` |
| `build-openjdk.yml` | OpenJDK 多架构镜像、loong64 镜像和 loong64 `.deb` Release | `openjdk/**`、`debian/10/rootfs/**`、`debian/12/rootfs/**`、`debian/13/Dockerfile`、`debian/13/loong64/**` |
| `build-wine.yml` | Wine Debian 12 镜像 | `debian/12/wine/**` |
| `build-wine-msvc.yml` | Wine + MSVC 镜像 | `debian/12/wine-msvc/**` |
| `build-darling.yml` | Darling Ubuntu 24.04 镜像 | `ubuntu/24.04/darling/**` |
| `build-osxcross.yml` | osxcross 镜像 | `ubuntu/24.04/osxcross/**` |
| `release-loong64-netinst-iso.yml` | loong64 netinst ISO 重打包和 GitHub Release 发布 | `loong64-netinst-*` tag 或手动触发 |

## Secrets

按使用到的 workflow 配置以下 secrets：

- `GH_KEY`：具备 `write:packages` 权限的 GitHub Personal Access Token，用于部分 GHCR 登录
- `GITHUB_TOKEN`：GitHub Actions 自动提供，用于仓库内 GHCR 发布和 Release 操作
- `REGISTRY_USERNAME`：阿里云容器镜像服务用户名
- `REGISTRY_PASSWORD`：阿里云容器镜像服务密码或访问令牌

## 维护约定

- 新增或修改镜像、tag、workflow、构建脚本、依赖、发布目标时，同步更新本 README。
- 每次提交前回顾代码变更，确认 README 是否需要更新；如果需要，必须和代码一起提交。
- workflow 的 matrix、发布 tag 和 README 的镜像列表要保持一致。
- 修改构建脚本后，尽量运行对应的 `test.sh` 或在 Pull Request 中确认 GitHub Actions 校验结果。
