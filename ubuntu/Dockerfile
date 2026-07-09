ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash vim \
        curl wget \
        ca-certificates \
        iputils-ping \
        telnet \
        ftp \
        net-tools iproute2 \
        procps \
        xz-utils \
        unzip \
        zip \
        bzip2 \
        file && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
