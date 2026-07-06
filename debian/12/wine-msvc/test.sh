#!/bin/bash
set -e

IMAGE_NAME="${1:-wine:msvc}"
DOCKER_CMD="${DOCKER_CMD:-docker}"

TTY_ARGS=""
if [ -t 0 ]; then
  TTY_ARGS="-it"
fi

$DOCKER_CMD run --rm ${TTY_ARGS} \
  -e WINEDEBUG=-all \
  "${IMAGE_NAME}" \
  bash -lc '
cat > hello.c <<EOF
#include <stdio.h>

int main(void) {
    printf("hello from MSVC under Wine\n");
    return 0;
}
EOF
/opt/msvc/bin/x64/cl /nologo hello.c
wine ./hello.exe
'
