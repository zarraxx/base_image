FROM ghcr.io/zarraxx/wine:debian-12

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEDEBUG=-all
ENV WINEPREFIX=/opt/wineprefix
ENV MSVC_DIR=/opt/msvc
ENV PATH="/opt/msvc/bin/x64:/opt/msvc/bin/x86:/opt/msvc/bin/arm64:/opt/msvc/bin/arm:${PATH}"

ARG MSVC_WINE_REPO=https://github.com/mstorsjo/msvc-wine.git
ARG MSVC_WINE_REF=master

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        msitools \
        winbind \
        cmake \
        ninja-build \
        perl \
        make \
        g++ \
        cabextract; \
    rm -rf /var/lib/apt/lists/*

# 初始化 Wine prefix，避免第一次运行 cl.exe 时才初始化
RUN set -eux; \
    mkdir -p "${WINEPREFIX}"; \
    WINE_BIN="$(command -v wine64 || command -v wine)"; \
    "${WINE_BIN}" wineboot --init; \
    while pgrep wineserver >/dev/null; do sleep 1; done

# 下载并安装 MSVC + Windows SDK 到 /opt/msvc
RUN set -eux; \
    git clone --depth 1 --branch "${MSVC_WINE_REF}" "${MSVC_WINE_REPO}" /tmp/msvc-wine; \
    cd /tmp/msvc-wine; \
    PYTHONUNBUFFERED=1 ./vsdownload.py --accept-license --dest "${MSVC_DIR}"; \
    ./install.sh "${MSVC_DIR}"; \
    rm -rf /tmp/msvc-wine; \
    find "${MSVC_DIR}" -name '*.tmp' -delete || true

WORKDIR /work

CMD ["/bin/bash"]