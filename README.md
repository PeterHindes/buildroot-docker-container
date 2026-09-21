# buildroot-docker-container

This repository publishes reusable Docker images for Buildroot-based projects.

## Image variants

### Generic builder

`buildroot-builder:<version>`

Contains:

- Ubuntu 24.04
- Buildroot host build dependencies
- Upstream Buildroot unpacked at `/opt/buildroot`

This image intentionally does **not** include project-specific `BR2_EXTERNAL` configuration or pre-downloaded project source archives.

### Network-project cached builder

`buildroot-builder:<version>-network`

Contains:

- everything in the generic builder image
- pre-downloaded source archives for `network_riscv32_defconfig` at `/opt/buildroot-dl`

This cached image still does **not** include a compiled RISC-V toolchain, Linux kernel, root filesystem, BusyBox, OpenSBI, or the project application binaries.

Its purpose is to skip first-build download latency so fresh builds can begin extraction/compilation immediately.

## Tag architecture

Generic tags (existing meaning preserved):

- `buildroot-builder:latest`
- `buildroot-builder:<BUILDROOT_VERSION>`
- `buildroot-builder:<BUILDROOT_SERIES>`

Network cached tags:

- `buildroot-builder:network-latest` (moving tag)
- `buildroot-builder:<BUILDROOT_VERSION>-network` (moving tag for that Buildroot release)
- `buildroot-builder:<BUILDROOT_VERSION>-network-<NETWORK_DEP_REVISION>` (immutable dependency snapshot tag)

`NETWORK_DEP_REVISION` is a deterministic hash derived from:

- `buildroot-external/configs/**`
- `buildroot-external/package/**`
- `buildroot-external/Config.in`
- `buildroot-external/external.desc`
- `buildroot-external/external.mk`
- `Dockerfile` / `Dockerfile.network`

## Runtime filesystem layout

At runtime, use these mounts:

- `/project`: bind-mount your project source from host.
- `/opt/buildroot`: Buildroot source tree baked into image.
- `/build`: Docker named volume for Buildroot output (`O=/build`).

The network cached image additionally contains:

- `/opt/buildroot-dl`: pre-populated Buildroot download cache.

Expected project shape:

```text
host project
├── app/
└── buildroot-external/

container
├── /project
│   ├── app/
│   └── buildroot-external/
├── /opt/buildroot
├── /opt/buildroot-dl
└── /build
```

## Persistent build volume

Create the persistent Buildroot output volume once:

```bash
docker volume create network-project-build
```

## Build commands (network cached image)

Load project defconfig:

```bash
docker run --rm -it \
    -v "$PWD:/project" \
    -v network-project-build:/build \
    <image-with-network-cache> \
    make -C /opt/buildroot \
        O=/build \
        BR2_DL_DIR=/opt/buildroot-dl \
        BR2_EXTERNAL=/project/buildroot-external \
        network_riscv32_defconfig
```

Build:

```bash
docker run --rm -it \
    -v "$PWD:/project" \
    -v network-project-build:/build \
    <image-with-network-cache> \
    make -C /opt/buildroot \
        O=/build \
        BR2_DL_DIR=/opt/buildroot-dl
```

If project dependencies change and `/opt/buildroot-dl` is missing some archives, Buildroot can still download the missing files into the container's writable layer (or an alternate writable `BR2_DL_DIR` you provide).

## GitHub Actions workflow

Workflow: `.github/workflows/docker-buildroot.yml`

Triggers include:

- Docker/build workflow changes
- project dependency-definition changes (`buildroot-external/configs/**`, `buildroot-external/package/**`, `buildroot-external/Config.in`, `buildroot-external/external.desc`, `buildroot-external/external.mk`)
- manual dispatch
- weekly schedule (to refresh base image/dependency updates)

Notably, ordinary app implementation changes (for example `app/src/*.c`) do not by themselves trigger the cached-image workflow.

The workflow:

1. Detects latest stable Buildroot release.
2. Computes deterministic `NETWORK_DEP_REVISION` hash for dependency metadata.
3. Builds smoke-test images for `linux/amd64` and `linux/arm64`.
4. Validates network cache image by checking:
   - `/opt/buildroot` exists,
   - `/opt/buildroot-dl` exists and has downloaded archives,
   - `network_riscv32_defconfig` loads,
   - `make source` succeeds,
   - no completed target build outputs are baked into the image.
5. Publishes multi-platform generic and network-cached manifests.

## Multi-platform and cache efficiency

Both variants publish `linux/amd64` and `linux/arm64` manifests.

`Dockerfile.network` computes the `/opt/buildroot-dl` cache in a BuildKit stage pinned to `$BUILDPLATFORM`, then copies that cache into each target-platform image. This avoids re-downloading architecture-independent Buildroot source archives separately for each target architecture during a single multi-platform build.

## Tradeoffs of embedding `/opt/buildroot-dl`

Benefits:

- Faster cold-start project builds.
- Predictable dependency availability for the validated defconfig.

Tradeoffs:

- Larger image size.
- Cached archives can lag if dependency metadata changes and image is not rebuilt.
- `<BUILDROOT_VERSION>-network` is intentionally a moving cache tag; use `<BUILDROOT_VERSION>-network-<NETWORK_DEP_REVISION>` when strict immutability is required.

## Required GitHub secrets

Set these repository secrets before publishing:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Credentials are only used by the workflow for Docker Hub authentication.
