#!/bin/bash

# --- 脚本配置 ---
# 如果任何命令失败，脚本将立即退出
set -e
# 定义镜像名称，方便后续修改
IMAGE_NAME="wine:debian-12"
DOCKER_CMD="${DOCKER_CMD:-docker}"

# --- 步骤 1: 清理悬空 (Orphan) 镜像 ---
echo "--> STEP 1: Pruning dangling (orphan) images..."
# podman image prune 会删除所有没有标签的镜像
# --force 选项可以在非交互式环境（如脚本）中自动回答 "yes"
$DOCKER_CMD image prune --force
echo "--> Pruning complete."
echo # 打印一个空行，方便阅读

# --- 步骤 2: 检查并删除已存在的旧镜像 ---
echo "--> STEP 2: Checking for and removing existing image: ${IMAGE_NAME}"
# 'image inspect' 在 Docker 和 Podman 中都可用，找到镜像则返回 0。
if $DOCKER_CMD image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo "Image found. Removing it now..."
    $DOCKER_CMD rmi "${IMAGE_NAME}"
    echo "Successfully removed '${IMAGE_NAME}'."
else
    echo "Image not found. Proceeding directly to build."
fi
echo # 打印一个空行

# --- 步骤 3: 构建新镜像 ---
echo "--> STEP 3: Building the new image: ${IMAGE_NAME}"

$DOCKER_CMD build \
  -t "${IMAGE_NAME}" .

echo # 打印一个空行
echo "--> BUILD COMPLETE! Image '${IMAGE_NAME}' is now ready to use."
