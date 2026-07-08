FROM debian:buster


ENV DEBIAN_FRONTEND=noninteractive

# 执行一个多步骤的 RUN 命令：
# 1. 切换到归档源 (archive.debian.org)
# 2. 更新包列表并安装 ca-certificates (启用 HTTPS 支持)
# 3. 切换到阿里云的 HTTPS 镜像源
# 4. 再次更新包列表，并清理缓存
RUN \
    # --- 步骤 1: 切换到 archive.debian.org (引导阶段) ---
    echo "==> STEP 1: Bootstrapping from archive.debian.org..." && \
    echo "deb http://archive.debian.org/debian/ buster main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security/ buster/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list && \
        \
    # --- 步骤 2: 更新并安装 HTTPS 支持 ---
    echo "==> STEP 2: Installing ca-certificates..." && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl wget \
        ca-certificates \
        python3 \
        python3-setuptools \
        xz-utils \
        unzip \
        zip \
        bzip2 \
        file && \
    rm -rf /var/lib/apt/lists/*