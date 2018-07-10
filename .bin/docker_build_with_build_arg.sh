#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"

# split `BUILD_ARG_VARIANTS` by `;`
IFS=';' read -ra VARIANTS <<< "${BUILD_ARG_VARIANTS}"
for VARIANT in "${VARIANTS[@]}"; do
    docker build -f ${IMAGES_DIR_FULL}/Dockerfile \
           -t gridx/${IMAGE_NAME}:${TAG}-${VARIANT} \
           --build-arg ${BUILD_ARG}=${VARIANT} \
           ${IMAGES_DIR_FULL}
done
