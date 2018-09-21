#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
IMAGES_DIR_FULL="${IMAGES_DIR}/${IMAGE_NAME}"
SUFFIX=${IMAGE_NAME_SUFFIX:-}
DOCKERFILE=Dockerfile

if [ ! -z ${TARGET_ARCH:-} ]; then 
    TAG=${TAG}-${TARGET_ARCH}
    DOCKERFILE=Dockerfile.${TARGET_ARCH}
    TARGET_ARCH=${TARGET_ARCH}/
fi

# split `BUILD_ARG_VARIANTS` by `;`
IFS=';' read -ra VARIANTS <<< "${BUILD_ARG_VARIANTS}"
for VARIANT in "${VARIANTS[@]}"; do
    # build unique image
    docker build -f ${IMAGES_DIR_FULL}/${DOCKERFILE} \
           -t gridx/${TARGET_ARCH:-}${IMAGE_NAME}${SUFFIX}:${TAG}-${VARIANT} \
           --build-arg ${BUILD_ARG}=${VARIANT} \
           ${IMAGES_DIR_FULL}

    # tag alias
    docker tag gridx/${TARGET_ARCH:-}${IMAGE_NAME}${SUFFIX}:${TAG}-${VARIANT} gridx/${TARGET_ARCH:-}${IMAGE_NAME}${SUFFIX}:${VARIANT}
done
