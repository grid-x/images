#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"
SUFFIX=${IMAGE_NAME_SUFFIX:-}

docker build -f ${IMAGES_DIR_FULL}/Dockerfile -t gridx/${IMAGE_NAME}${SUFFIX}:$TAG ${IMAGES_DIR_FULL}

# tag alias
docker tag gridx/${IMAGE_NAME}${SUFFIX}:$TAG gridx/${IMAGE_NAME}${SUFFIX}
