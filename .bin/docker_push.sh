#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)
SUFFIX=${IMAGE_NAME_SUFFIX:-}

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
docker push gridx/${IMAGE_NAME}${SUFFIX}:$TAG

# push alias
docker push gridx/${IMAGE_NAME}${SUFFIX}
