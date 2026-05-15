#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export DOCKER_PLATFORM="linux/amd64"
export DOCKER_IMAGE="hcly-behavior-desktop-packager:py311-bullseye-amd64"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/package.env"

printf '==> 构建 Docker 打包镜像: %s (%s)\n' "${DOCKER_IMAGE}" "${DOCKER_PLATFORM}"
if [[ "${HCLY_DOCKER_CACHE:-}" == "gha" ]]; then
    CACHE_SCOPE="${HCLY_DOCKER_CACHE_SCOPE:-${DOCKER_IMAGE//[\/:]/-}}"
    docker buildx build \
        --platform "${DOCKER_PLATFORM}" \
        -f "${SCRIPT_DIR}/Dockerfile" \
        -t "${DOCKER_IMAGE}" \
        --load \
        --cache-from "type=gha,scope=${CACHE_SCOPE}" \
        --cache-to "type=gha,mode=max,scope=${CACHE_SCOPE}" \
        "${PROJECT_ROOT}"
else
    docker build --platform "${DOCKER_PLATFORM}" -f "${SCRIPT_DIR}/Dockerfile" -t "${DOCKER_IMAGE}" "${PROJECT_ROOT}"
fi

printf '\n==> 生成 Linux amd64 deb 离线包\n'
docker run --rm --platform "${DOCKER_PLATFORM}" \
    -e APP_ID="${APP_ID}" \
    -e APP_DISPLAY_NAME="${APP_DISPLAY_NAME}" \
    -e APP_VERSION="${APP_VERSION}" \
    -e APP_MAINTAINER="${APP_MAINTAINER}" \
    -e BUNDLE_SYSTEM_LIBS="${BUNDLE_SYSTEM_LIBS}" \
    -e BUNDLE_GLIBC="${BUNDLE_GLIBC}" \
    -e KEEP_WAYLAND="${KEEP_WAYLAND}" \
    -e KEEP_EXTRA_QML="${KEEP_EXTRA_QML}" \
    -e ENABLE_UPX="${ENABLE_UPX}" \
    -v "${PROJECT_ROOT}:/workspace" \
    "${DOCKER_IMAGE}" \
    /bin/bash /workspace/docker/build-in-container.sh deb
