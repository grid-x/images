#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"
SUFFIX=${IMAGE_NAME_SUFFIX:-}

if [ ! -z ${TARGET_ARCH:-} ]; then 
    TAG=${TAG}-${TARGET_ARCH}
    TARGET_ARCH=${TARGET_ARCH}/
fi

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

# split `BUILD_ARG_VARIANTS` by `;`
IFS=';' read -ra VARIANTS <<< "${BUILD_ARG_VARIANTS}"
for VARIANT in "${VARIANTS[@]}"; do
    # push unique image
    docker push gridx/${TARGET_ARCH:-}${IMAGE_NAME}${SUFFIX}:${TAG}-${VARIANT}

    # push alias
    docker push gridx/${TARGET_ARCH:-}${IMAGE_NAME}${SUFFIX}:${VARIANT}
done
