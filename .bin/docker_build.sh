#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"

docker build -f ${IMAGES_DIR_FULL}/Dockerfile -t gridx/${IMAGE_NAME}:$TAG ${IMAGES_DIR_FULL}
