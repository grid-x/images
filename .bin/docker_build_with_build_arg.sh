#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"
SUFFIX=${IMAGE_NAME_SUFFIX:-}

# split `BUILD_ARG_VARIANTS` by `;`
IFS=';' read -ra VARIANTS <<< "${BUILD_ARG_VARIANTS}"
for VARIANT in "${VARIANTS[@]}"; do
    # build unique image
    docker build -f ${IMAGES_DIR_FULL}/Dockerfile \
           -t gridx/${IMAGE_NAME}${SUFFIX}:${TAG}-${VARIANT} \
           --build-arg ${BUILD_ARG}=${VARIANT} \
           ${IMAGES_DIR_FULL}

    # tag alias
    docker tag gridx/${IMAGE_NAME}${SUFFIX}:${TAG}-${VARIANT} gridx/${IMAGE_NAME}${SUFFIX}:${VARIANT}
done
