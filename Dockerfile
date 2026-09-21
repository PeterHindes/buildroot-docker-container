FROM ubuntu:24.04

ARG BUILDROOT_VERSION
ARG BUILDROOT_BASE_URL="https://buildroot.org/downloads"

LABEL org.opencontainers.image.description="Reusable Buildroot builder image with upstream Buildroot sources at /opt/buildroot"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        bc \
        binutils \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        cpio \
        curl \
        file \
        findutils \
        flex \
        g++ \
        gcc \
        git \
        gzip \
        libncurses-dev \
        make \
        patch \
        perl \
        python3 \
        rsync \
        sed \
        tar \
        unzip \
        wget \
        which \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN test -n "${BUILDROOT_VERSION}" \
    && archive="buildroot-${BUILDROOT_VERSION}.tar.gz" \
    && curl -fsSLO "${BUILDROOT_BASE_URL}/${archive}" \
    && curl -fsSLO "${BUILDROOT_BASE_URL}/${archive}.sha256" \
    && checksum="$(awk -v f="${archive}" '$2 == f {print $1}' "${archive}.sha256")" \
    && test -n "${checksum}" \
    && echo "${checksum}  ${archive}" | sha256sum -c - \
    && mkdir -p /opt \
    && tar -xzf "${archive}" -C /opt \
    && mv "/opt/buildroot-${BUILDROOT_VERSION}" /opt/buildroot \
    && rm -f "${archive}" "${archive}.sha256"

WORKDIR /project
