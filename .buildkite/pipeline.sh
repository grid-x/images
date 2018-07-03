#!/bin/bash
set -euo pipefail

ROOT_PIPELINE_TEMPLATE=.buildkite/pipeline.template.yaml
export ROOT_PIPELINE_CONFIG=.buildkite/pipeline.yaml
export IMAGES_DIR=images
export IMAGES_PIPELINE_CONFIG=pipeline.yaml

# diff current commit to last
commitGetDiff() {
    git diff ${BUILDKITE_COMMIT}..master --name-only
}
export -f commitGetDiff

# check for changes outside images folder
commitIsDirty() {
    commitGetDiff | grep -qcv ${IMAGES_DIR}
}

# get list of all images
imagesList() {
    find ./${IMAGES_DIR} -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# rebuild image, if possible
imageTrigger() {
    if [ ! -f "${IMAGES_DIR}/$1/${IMAGES_PIPELINE_CONFIG}" ]; then
        printf "%-30s ⚠ need rebuild - pipeline missing\n" $1
    else
        printf "%-30s ✖ need rebuild\n" $1
        cat "${IMAGES_DIR}/$1/${IMAGES_PIPELINE_CONFIG}" >> ${ROOT_PIPELINE_CONFIG}
    fi
}
export -f imageTrigger

# check for changes inside specific image folder
imageIsDirty() {
   commitGetDiff | grep -qc "^${IMAGES_DIR}/$1"
}
export -f imageIsDirty

# if a specific image needs a rebuild, trigger its pipeline
imageTriggerMaybe() {
    if [ "$2" -eq 1 ] || imageIsDirty $1; then
        # commit or image is dirty, try to rebuild
        imageTrigger $1
    else
        printf "%-30s ✓ up to date\n" $1
    fi
}
export -f imageTriggerMaybe

pipelineTriggerAll() {
    imagesList | xargs -n1 -I{} bash -c "imageTriggerMaybe {} $1"
}

main() {
    rm "${ROOT_PIPELINE_CONFIG}"
    cp "${ROOT_PIPELINE_TEMPLATE}" "${ROOT_PIPELINE_CONFIG}"
    if commitIsDirty; then
        echo -e "commit is dirty, triggering pipeline for all images \n"
        pipelineTriggerAll 1
    else
        echo -e "commit is clean, triggering pipeline for changed images only \n"
        pipelineTriggerAll 0
    fi
}

main
