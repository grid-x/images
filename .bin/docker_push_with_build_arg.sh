#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"

# split `BUILD_ARG_VARIANTS` by `;`
IFS=';' read -ra VARIANTS <<< "${BUILD_ARG_VARIANTS}"
for VARIANT in "${VARIANTS[@]}"; do
    # push unique image
    docker push gridx/${IMAGE_NAME}:${TAG}-${VARIANT}

    # push alias
    docker push gridx/${IMAGE_NAME}:${VARIANT}
done
