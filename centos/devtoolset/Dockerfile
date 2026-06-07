# 使用 CentOS 7 作为基础镜像
FROM ghcr.io/zarraxx/centos:centos7

# --- 系统配置和依赖安装 ---
# 将所有安装步骤合并到一个 RUN 层，以减小镜像体积+


# ------------------[ EOL HOTFIX START ]------------------
# 1. 根据架构切换 CentOS 7 仓库
#    x86_64 -> centos-vault
#    aarch64 -> centos-altarch
RUN set -e; \
    arch="$(uname -m)"; \
    if [ "$arch" = "aarch64" ]; then \
        centos_base="https://mirrors.aliyun.com/centos-altarch"; \
        centos_base_src="http://mirror.centos.org/altarch"; \
    else \
        centos_base="https://mirrors.aliyun.com/centos-vault"; \
        centos_base_src="http://mirror.centos.org"; \
    fi; \
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*; \
    sed -i "s|#baseurl=${centos_base_src}|baseurl=${centos_base}|g" /etc/yum.repos.d/CentOS-*

RUN yum install -y epel-release && \
    sed -i 's/metalink=/#metalink=/g' /etc/yum.repos.d/epel.repo && \
    sed -i 's|#baseurl=http://download.fedoraproject.org/pub/epel|baseurl=https://mirrors.aliyun.com/epel-archive|g' /etc/yum.repos.d/epel.repo


# 4. 修复 SCL 仓库指向阿里云 Vault/AltArch
RUN set -e; \
    arch="$(uname -m)"; \
    if [ "$arch" = "aarch64" ]; then \
        scl_base="https://mirrors.aliyun.com/centos-altarch"; \
        centos_base_src="http://mirror.centos.org/centos"; \
    else \
        scl_base="https://mirrors.aliyun.com"; \
        centos_base_src="http://mirror.centos.org"; \
    fi; \
    yum install -y centos-release-scl; \
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-SCLo-scl*.repo; \
    sed -i "s|# baseurl=${centos_base_src}|baseurl=${scl_base}|g" /etc/yum.repos.d/CentOS-SCLo-scl*.repo; \
    sed -i "s|#baseurl=${centos_base_src}|baseurl=${scl_base}|g" /etc/yum.repos.d/CentOS-SCLo-scl*.repo


RUN yum install -y \
    devtoolset-10-gcc \
    devtoolset-10-gcc-c++ \
    devtoolset-10-binutils \
    make \
    git \
    wget \
    patch \
    unzip bzip2 lzma flex bison nasm help2man which file \
    perl perl-Data-Dumper perl-Pod-Markdown perl-IPC-Cmd perl-Thread-Queue perl-ExtUtils-Embed perl-ExtUtils-Embed \
    pam-devel systemd-devel \
    zlib-devel lz4-devel bzip2-devel xz-devel \
    && yum clean all

ENV PATH=/opt/rh/devtoolset-10/root/usr/bin:$PATH \
    PKG_CONFIG_PATH=/opt/rh/devtoolset-10/root/usr/lib64/pkgconfig:$PKG_CONFIG_PATH \
    MANPATH=/opt/rh/devtoolset-10/root/usr/share/man:$MANPATH
