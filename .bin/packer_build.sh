#!/usr/bin/env bash
set -eou pipefail

IMAGES_DIR_FULL="${PWD}/${IMAGES_DIR}/${IMAGE_NAME}"
PACKER_DIR="/packer"
CONFIG_FILE=${PACKER_CONFIG_FILE:-packer.json}

docker run -it \
  -v ${IMAGES_DIR_FULL}:${PACKER_DIR} \
  -w ${PACKER_DIR} \
  hashicorp/packer:light \
  build ${CONFIG_FILE}
