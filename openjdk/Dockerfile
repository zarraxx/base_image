ARG BASE_IMAGE=ghcr.io/zarraxx/debian:trixie
FROM ${BASE_IMAGE}

ARG JAVA_VERSION=8
ARG ENABLE_STRETCH_OPENJDK8=false
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    if [ "${ENABLE_STRETCH_OPENJDK8}" = "true" ]; then \
        echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99debian-archive; \
        { \
            echo 'deb http://archive.debian.org/debian stretch main'; \
            echo 'deb http://archive.debian.org/debian-security stretch/updates main'; \
        } > /etc/apt/sources.list.d/stretch-openjdk8.list; \
    fi; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        openjdk-${JAVA_VERSION}-jdk-headless && \
    rm -f /etc/apt/sources.list.d/stretch-openjdk8.list /etc/apt/apt.conf.d/99debian-archive && \
    rm -rf /var/lib/apt/lists/*
