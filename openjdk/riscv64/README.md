# OpenJDK riscv64 Debian Package

Ubuntu 24.04 and 26.04 riscv64 do not ship installable OpenJDK 8 JDK/JRE
packages. This directory repacks the openSUSE Tumbleweed riscv64 OpenJDK 8
Zero VM RPM packages into a Debian `riscv64` package for the OpenJDK 8 image.

## Source RPMs

The package is built from the official openSUSE ports repository:

- `java-1_8_0-openjdk-headless-1.8.0.492-4.1.riscv64.rpm`
- `java-1_8_0-openjdk-devel-1.8.0.492-4.1.riscv64.rpm`
- `java-1_8_0-openjdk-1.8.0.492-4.1.riscv64.rpm`

Base URL:

```text
https://download.opensuse.org/ports/riscv/tumbleweed/repo/oss/riscv64
```

## Build

```bash
cd openjdk/riscv64
./build.sh
```

The output package is written to `dist/openjdk-8-jdk_*_riscv64.deb`.

## Test

Use a riscv64-capable container runtime and QEMU/binfmt:

```bash
cd openjdk/riscv64
CONTAINER_TOOL=podman IMAGE=ghcr.io/zarraxx/ubuntu:resolute ./test.sh
```
