FROM debian:10

# 设置环境变量，防止 apt 在构建过程中进行交互式提问
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
    \
    # --- 步骤 2: 更新并安装 HTTPS 支持 ---
    echo "==> STEP 2: Installing ca-certificates..." && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl wget && \
     \
    # --- 步骤 3: 切换到阿里云镜像源 ---
    echo "==> STEP 3: Switching to Aliyun mirrors..." && \
    echo "deb https://mirrors.aliyun.com/debian-archive/debian/ buster main non-free contrib" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-archive/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-archive/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list && \
    \
    # --- 步骤 4: 从新源更新并清理 ---
    echo "==> STEP 4: Final update and cleanup..." && \
    apt-get update


# 设置默认命令，方便测试
CMD ["bash"]