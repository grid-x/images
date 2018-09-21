#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"
SUFFIX=${IMAGE_NAME_SUFFIX:-}
DOCKERFILE=Dockerfile

if [ ! -z ${TARGET_ARCH:-} ]; then 
    TAG=${TAG}-${TARGET_ARCH}
    DOCKERFILE=Dockerfile.${TARGET_ARCH}
    TARGET_ARCH=-${TARGET_ARCH}
fi

docker build -f ${IMAGES_DIR_FULL}/${DOCKERFILE} \
    -t gridx/${IMAGE_NAME}${SUFFIX}${TARGET_ARCH:-}:$TAG \
    ${IMAGES_DIR_FULL}

# tag alias
docker tag gridx/${IMAGE_NAME}${SUFFIX}${TARGET_ARCH:-}:$TAG gridx/${IMAGE_NAME}${SUFFIX}${TARGET_ARCH:-}
