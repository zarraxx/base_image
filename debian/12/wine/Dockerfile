FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

ENV DEBIAN_FRONTEND=noninteractive
ENV DEPOT_TOOLS=/opt/depot_tools
ENV PATH="${DEPOT_TOOLS}:${PATH}"

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        python3 \
        python3-distutils \
        build-essential \
        pkg-config \
        ninja-build \
        clang \
        lld \
        xz-utils \
        unzip \
        zip \
        bzip2 \
        file \
        sudo \
        wine \
        wine32 \
        wine64 \
        libwine \
        libwine:i386 \
        fonts-wine && \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ${DEPOT_TOOLS} && \
    rm -rf /var/lib/apt/lists/*