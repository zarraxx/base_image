ARG UBUNTU_VERSION="24.04"

FROM ubuntu:${UBUNTU_VERSION} as build

ENV DEBIAN_FRONTEND=noninteractive

ARG OSX_SDK_VERSION="11.3"
ARG OSX_SDK="MacOSX${OSX_SDK_VERSION}.sdk"
ARG OSX_SDK_URL="https://github.com/joseluisq/macosx-sdks/releases/download/${OSX_SDK_VERSION}/${OSX_SDK}.tar.xz"
ARG OSX_CROSS_COMMIT="e6ab3fa7423f9235ce9ed6381d6d3af191b46b59"

RUN export DEBIAN_FRONTEND="noninteractive" \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    bash curl \
    binutils-multiarch-dev \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    git \
    libbz2-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    liblzma-dev \
    libpsi3-dev \
    libssl-dev \
    libxml2-dev \
    libz-dev \
    llvm-dev \
    lzma-dev \
    make \
    patch \
    python3 \
    uuid-dev \
    wget \
    xz-utils \
    zlib1g-dev


WORKDIR /osxcross
ADD "https://github.com/tpoechtrager/osxcross.git#${OSX_CROSS_COMMIT}" .
COPY patches/lcxx.patch .
RUN patch -p1 < lcxx.patch
RUN mkdir -p tarballs && curl -sSL "$OSX_SDK_URL" -o "tarballs/$OSX_SDK.tar.xz"

RUN OSX_VERSION_MIN=10.13 UNATTENDED=1 ENABLE_COMPILER_RT_INSTALL=1 TARGET_DIR=/opt/osxcross ./build.sh


FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/osxcross/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    clang make cmake git curl wget python3 patch bash build-essential ninja-build  meson \
    file \
    lld \
    libc6-dev \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --link --from=build /opt/osxcross /opt/osxcross