# buildroot-docker-container

This repository publishes a reusable Docker image for Buildroot-based projects.

## What the image contains

The `buildroot-builder` image is built from `ubuntu:24.04` and includes:

- Buildroot host build dependencies needed for general Buildroot development.
- An upstream Buildroot release unpacked at `/opt/buildroot`.

The image intentionally does **not** include your application code or `BR2_EXTERNAL` tree.

## Why Buildroot runs in Docker on macOS

On macOS, bind-mounted filesystems (VirtioFS/APFS) can cause incompatibilities during Linux source extraction/build steps. This image keeps Buildroot sources and Buildroot-generated artifacts on Linux Docker filesystems to avoid those host filesystem issues.

## Filesystem layout

At runtime, use these mounts:

- `/project`: bind-mount your project source from macOS/Linux host.
- `/opt/buildroot`: Buildroot source tree baked into the image.
- `/build`: Docker named volume for Buildroot output (`O=/build`).

Expected shape:

```text
host project
├── app/
└── buildroot-external/

container
├── /project
│   ├── app/
│   └── buildroot-external/
├── /opt/buildroot
└── /build
    ├── .config
    ├── build/
    ├── host/
    ├── staging/
    ├── target/
    └── images/
```

## Persistent build volume

Create the persistent Buildroot output volume once:

```bash
docker volume create network-project-build
```

## Load external defconfig

```bash
docker run --rm -it \
    -v "$PWD:/project" \
    -v network-project-build:/build \
    <image> \
    make -C /opt/buildroot \
        O=/build \
        BR2_EXTERNAL=/project/buildroot-external \
        network_riscv32_defconfig
```

## Build after configuration

```bash
docker run --rm -it \
    -v "$PWD:/project" \
    -v network-project-build:/build \
    <image> \
    make -C /opt/buildroot O=/build
```

`buildroot-external/configs/` stores your project configuration sources. `/build/.config` is generated Buildroot working state persisted in the Docker volume.

## GitHub Actions workflow

Workflow: `.github/workflows/docker-buildroot.yml`

It runs on:

- changes to Docker/workflow/release-detection files,
- manual dispatch,
- a weekly schedule.

The workflow:

1. Detects the latest stable Buildroot release from `https://buildroot.org/downloads/` (excluding `-rc*` releases).
2. Builds smoke-test images for `linux/amd64` and `linux/arm64`.
3. Verifies at minimum:
   - `/opt/buildroot/Makefile` exists,
   - `make`, `gcc`, and `python3` are available,
   - `make -C /opt/buildroot help` succeeds.
4. Publishes a multi-platform image to Docker Hub with tags:
   - `latest`
   - `<BUILDROOT_VERSION>` (for example `2026.02.1`)
   - `<BUILDROOT_SERIES>` (for example `2026.02`)

The scheduled rebuild also refreshes images when Ubuntu base image or apt package updates occur, even if the Buildroot version is unchanged.

## Required GitHub secrets

Set these repository secrets before publishing:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

The workflow reads these secrets at runtime for Docker Hub authentication. Credentials are not stored in the Dockerfile/image.
