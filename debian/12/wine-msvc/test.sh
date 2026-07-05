IMAGE_NAME="${1:-wine:msvc}"
DOCKER_CMD="${DOCKER_CMD:-docker}"

$DOCKER_CMD run --rm -it \
  -e WINEDEBUG=-all \
  ${IMAGE_NAME} \
  bash -lc '
cat > hello.c <<EOF
#include <stdio.h>

int main(void) {
    printf("hello from MSVC under Wine\n");
    return 0;
}
EOF
ls
/opt/msvc/bin/x64/cl /nologo hello.c
ls
wine ./hello.exe
'