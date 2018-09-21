#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
SUFFIX=${IMAGE_NAME_SUFFIX:-}

if [ ! -z ${TARGET_ARCH:-} ]; then 
    TAG=${TAG}-${TARGET_ARCH}
    TARGET_ARCH=-${TARGET_ARCH}
fi

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
docker push gridx/${IMAGE_NAME}${SUFFIX}${TARGET_ARCH:-}:$TAG


# push alias
docker push gridx/${IMAGE_NAME}${SUFFIX}${TARGET_ARCH:-}
