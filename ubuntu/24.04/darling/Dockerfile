FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ARG DARLING_URL="https://github.com/darlinghq/darling/releases/download/v0.1.20260608/debs_20260608.zip"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        xz-utils \
        file \
        bash \
        procps \
        util-linux \
        fuse3 \
        dbus \
        locales; \
    curl -L --retry 5 --retry-delay 2 \
        "$DARLING_URL" \
        -o /tmp/darling-debs.zip; \
    mkdir -p /tmp/darling-debs; \
    unzip /tmp/darling-debs.zip -d /tmp/darling-debs; \
    apt-get install -y --no-install-recommends /tmp/darling-debs/debs_*/*.deb; \
    rm -rf \
        /tmp/darling-debs.zip \
        /tmp/darling-debs \
        /var/lib/apt/lists/*

WORKDIR /work

CMD ["bash"]