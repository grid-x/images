#!/usr/bin/env bash
set -eou pipefail

TAG=$(.bin/git_tag.sh)

docker push gridx/${IMAGE_NAME}:$TAG
