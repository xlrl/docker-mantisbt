#!/bin/sh
#
# Build the multi-arch mantisbt image using podman and tag it as
# docker.io/xlrl/mantisbt:latest and docker.io/xlrl/mantisbt:<version>.
#
# Env:
#   PLATFORMS  comma separated target platforms
#              (default: linux/amd64,linux/arm64)
#
# Cross builds need qemu-user-static (apt-get install qemu-user-static).

set -eu

cd "$(dirname "$0")"

version=$(sed -n 's/^ENV MANTIS_VER=\(.*\)$/\1/p' Dockerfile)
platforms=${PLATFORMS:-linux/amd64,linux/arm64}

image=docker.io/xlrl/mantisbt
manifest="${image}:${version}"

# Start from a fresh manifest list
if podman manifest exists "${manifest}"; then
    podman manifest rm "${manifest}"
fi

podman build \
    --platform "${platforms}" \
    --manifest "${manifest}" \
    .

podman tag "${manifest}" "${image}:latest"
