#!/bin/bash
set -e

IMAGE_NAME="${1:-darling:noble-20260608}"
DOCKER_CMD="${DOCKER_CMD:-docker}"

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  $DOCKER_CMD run --rm \
    "${IMAGE_NAME}" \
    bash -lc 'set -e; command -v darling; dpkg-query -W | grep -i "^darling"; echo hello-from-darling-image'
  exit 0
fi

$DOCKER_CMD run --rm \
  --privileged \
  --security-opt seccomp=unconfined \
  -v "$PWD":/work \
  "${IMAGE_NAME}" \
  darling shell /bin/sh -lc 'uname -a; echo hello-from-darling'


# sudo podman run --rm -it \
#   --privileged \
#   --security-opt seccomp=unconfined \
#   --security-opt label=disable \
#   -v "$PWD":/work \
#   darling:noble-20260608 \
#   darling shell /bin/sh -lc 'uname -a; echo hello-from-darling'
