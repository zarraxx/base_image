# Loong64 OpenJDK Debian Packages

Debian loong64 当前缺少官方 OpenJDK 包。本目录用于把 Loongnix 官方发布的 loongarch64 glibc tarball binary 重打包成 Debian `loong64` 架构的 `.deb` 包，并通过 `update-alternatives` 注册常用 JDK/JRE 命令。

## 版本来源

| Debian 包名 | 版本目录 | 版本 | Loongnix tarball |
| --- | --- | --- | --- |
| `openjdk-8-jdk` | `8/` | `8u492-b09+loongnix1` | `https://ftp.loongnix.cn/Java/openjdk8/loongson8.1.27-fx-jdk8u492b09-linux-loongarch64-glibc2.34.tar.gz` |
| `openjdk-11-jdk` | `11/` | `11.0.31+11+loongnix1` | `https://ftp.loongnix.cn/Java/openjdk11/loongson11.18.27-fx-jdk11.0.31_11-linux-loongarch64-glibc2.34.tar.gz` |
| `openjdk-17-jdk` | `17/` | `17.0.19+10+loongnix1` | `https://ftp.loongnix.cn/Java/openjdk17/loongson17.18.25-fx-jdk17.0.19_10-linux-loongarch64-glibc2.34.tar.gz` |
| `openjdk-21-jdk` | `21/` | `21.0.11+10+loongnix1` | `https://ftp.loongnix.cn/Java/openjdk21/loongson21.11.38-fx-jdk21.0.11_10-linux-loongarch64-glibc2.34.tar.gz` |
| `openjdk-25-jdk` | `25/` | `25.0.3+9+loongnix1` | `https://ftp.loongnix.cn/Java/openjdk25/loongson25.4.28-fx-jdk25.0.3_9-linux-loongarch64-glibc2.34.tar.gz` |

每个版本目录按 Debian 二进制包结构维护自己的文件：

```text
<major>/
├── package.conf
├── DEBIAN
│   ├── control
│   ├── postinst
│   └── prerm
└── usr
    └── share/doc/openjdk-<major>-jdk
```

`build.sh` 只负责切换到版本目录、读取 `package.conf`、下载 Loongnix tarball、把 JDK 内容安装到 `JAVA_HOME`，最后调用 `dpkg-deb --build`。

## 构建

构建全部五个包：

```bash
./build.sh
```

只构建指定 major 版本：

```bash
./build.sh 17 21
```

默认输出目录：

```text
dist/
```

默认下载缓存目录：

```text
.cache/
```

可通过环境变量覆盖：

```bash
OUT_DIR=/tmp/openjdk-debs CACHE_DIR=/tmp/openjdk-cache ./build.sh
```

## 测试

使用支持 loong64 的 `ghcr.io/zarraxx/debian:trixie` 镜像和 QEMU/binfmt 测试安装、运行和 `update-alternatives` 切换：

```bash
./test.sh
```

也可以指定镜像或包目录：

```bash
IMAGE=ghcr.io/zarraxx/debian:trixie DIST_DIR=dist ./test.sh
```

测试脚本会在 `linux/loong64` 容器中安装全部 `.deb`，逐个 JDK 直接运行 `java` / `javac` 编译执行 `Hello.java`，再逐个切换 `java` / `javac` alternatives 并重复编译运行测试。

OpenJDK 8 在 GitHub Actions 的 loong64 QEMU 环境中会使用 `JAVA_TOOL_OPTIONS=-Xint` 运行测试，以避开 Loongnix JDK 8 HotSpot JIT 在该模拟环境下的崩溃；包内容和默认运行参数不因此改变。

## 包行为

每个包安装到：

```text
/usr/lib/jvm/loongson-<major>-jdk-loong64
```

安装后会为对应版本 tarball 中实际存在的常用命令注册 `update-alternatives`。例如 OpenJDK 8 没有 `jmod`、`jlink`、`jshell`、`jpackage`；这些命令只应在新版本包里注册。卸载包时会清理对应 alternatives。

新版 JDK 的 alternatives 优先级更高，因此多个版本同时安装时，自动模式默认选择最高版本。可以手动切换：

```bash
update-alternatives --config java
update-alternatives --config javac
```
