#!/usr/bin/env bash
set -euo pipefail

IMAGE="docker.io/xlrl/mantisbt"
PLATFORMS="linux/amd64,linux/arm64"
TAG="${MANTIS_VER:-$(grep -oP '^ENV MANTIS_VER=\K.*' Dockerfile)}"
CMD="build"

usage() {
    cat >&2 <<EOF
Usage: $0 [-p|--platforms <os/arch[,os/arch...]>] [login|build|push]

  login   log in to docker.io
  build   build image(s) for PLATFORMS, tag :TAG and :latest (default)
  push    push manifest list as :TAG and :latest

Default platforms: ${PLATFORMS}
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--platforms)
            if [[ $# -lt 2 ]]; then
                usage
                exit 1
            fi
            PLATFORMS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        login|build|push)
            CMD="$1"
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

login() {
    podman login docker.io
}

build() {
    podman build \
        --platform "${PLATFORMS}" \
        --manifest "${IMAGE}:${TAG}" \
        .
    podman tag "${IMAGE}:${TAG}" "${IMAGE}:latest"
}

push() {
    podman manifest push "${IMAGE}:${TAG}" "docker://${IMAGE}:${TAG}"
    podman manifest push "${IMAGE}:${TAG}" "docker://${IMAGE}:latest"
}

case "${CMD}" in
    login) login ;;
    build) build ;;
    push) push ;;
esac
