#!/bin/sh
#
# Build the multi-arch mantisbt image using podman and tag it as
# localhost/xlrl/mantisbt:latest and localhost/xlrl/mantisbt:<version>.
# Never pushes; prints the push commands.
#
# Env:
#   PLATFORMS  comma separated target platforms
#              (default: linux/amd64,linux/arm64)
#
# Cross builds need qemu-user-static (apt-get install qemu-user-static).

set -eu

cd "$(dirname "$0")"

version=$(cat VERSION)
platforms=${PLATFORMS:-linux/amd64,linux/arm64}

image=localhost/xlrl/mantisbt
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

echo "Built ${image}:${version} and :latest (${platforms})"
echo "Push with:"
echo "  podman manifest push --all ${image}:${version} docker://<registry>/xlrl/mantisbt:${version}"
echo "  podman manifest push --all ${image}:latest docker://<registry>/xlrl/mantisbt:latest"
