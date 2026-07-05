#!/bin/bash
set -e

IMAGE_NAME="${1:-wine:debian-12}"
DOCKER_CMD="${DOCKER_CMD:-docker}"

$DOCKER_CMD run --rm \
  -e WINEDEBUG=-all \
  "${IMAGE_NAME}" \
  wine cmd /c ver
