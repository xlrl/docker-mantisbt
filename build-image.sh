#!/bin/sh
#
# Build the multi-arch mantisbt image using podman.
# Never pushes; prints the push commands.
#
# Usage: build-image.sh [TAG]
#   TAG  tag as localhost/xlrl/mantisbt:TAG only
#        (default: tag as :<VERSION> and :latest)
#
# Env:
#   PLATFORMS  comma separated target platforms
#              (default: linux/amd64,linux/arm64)
#
# Cross builds need qemu-user-static (apt-get install qemu-user-static).

set -eu

cd "$(dirname "$0")"

image=localhost/xlrl/mantisbt
platforms=${PLATFORMS:-linux/amd64,linux/arm64}

if [ $# -gt 0 ]; then
    tags=$1
else
    tags="$(cat VERSION) latest"
fi

# first tag is the manifest, the others are aliases
set -- ${tags}
manifest="${image}:$1"
shift

# Start from a fresh manifest list
if podman manifest exists "${manifest}"; then
    podman manifest rm "${manifest}"
fi

podman build \
    --platform "${platforms}" \
    --manifest "${manifest}" \
    .

for tag in "$@"; do
    podman tag "${manifest}" "${image}:${tag}"
done

echo "Built ${image}: ${tags} (${platforms})"
echo "Push with:"
for tag in ${tags}; do
    echo "  podman manifest push --all ${image}:${tag} docker://<registry>/xlrl/mantisbt:${tag}"
done
