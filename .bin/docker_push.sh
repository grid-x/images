#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
docker push gridx/${IMAGE_NAME}:$TAG
