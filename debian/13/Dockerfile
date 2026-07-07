FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl wget \
        ca-certificates \
        python3 \
        python3-setuptools \
        xz-utils \
        unzip \
        zip \
        bzip2 \
        file && \
    rm -rf /var/lib/apt/lists/*
