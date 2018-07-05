#!/usr/bin/env bash
set -euo pipefail

############################
#
# Dynamic Buildkite Pipeline
#
# DESCRIPTION:
#   diffs current commit to previous
#   to decide which images need to be rebuilt.
#
#   if an image needs a rebuild, this script will concat
#   the images pipeline config onto the global pipeline template.
#
#   if there are changes outside the images folder,
#   fall back to rebuilding all images.
#
# USAGE:
#   .buildkite/pipeline.sh | buildkite-agent pipeline upload
#
###########################

ROOT_PIPELINE_TEMPLATE=.buildkite/pipeline.template.yaml
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
imageEnable() {
    IMAGE_ID="$1"
    if [ ! -f "${IMAGES_DIR}/${IMAGE_ID}/${IMAGES_PIPELINE_CONFIG}" ]; then
        printf "%-40s ⚠ need rebuild - pipeline missing\n" $1 >&2
    else
        printf "%-40s ✖ need rebuild\n" $1 >&2
        cat "${IMAGES_DIR}/${IMAGE_ID}/${IMAGES_PIPELINE_CONFIG}"
    fi
}
export -f imageEnable

# if a specific image needs a rebuild, enable its pipeline
imageEnableMaybe() {
    IMAGE_ID="$1"
    COMMIT_IS_DIRTY="$2"
    if [ "${COMMIT_IS_DIRTY}" -eq 1 ] || imageIsDirty ${IMAGE_ID}; then
        # commit or image is dirty, try to rebuild
        imageEnable $1
    else
        printf "%-40s ✓ up to date\n" ${IMAGE_ID} >&2
    fi
}
export -f imageEnableMaybe

# check for changes inside specific image folder
imageIsDirty() {
    IMAGE_ID="$1"
    commitGetDiff | grep -qc "^${IMAGES_DIR}/${IMAGE_ID}"
}
export -f imageIsDirty

pipelineEnableAll() {
    COMMIT_IS_DIRTY="$1"
    imagesList | xargs -n1 -I{} bash -c "imageEnableMaybe {} ${COMMIT_IS_DIRTY}"
}

main() {
    cat "${ROOT_PIPELINE_TEMPLATE}"
    echo "+++ Checking images" >&2
    if commitIsDirty; then
        echo -e "commit is dirty, enabling pipeline for all images \n" >&2
        pipelineEnableAll 1
    else
        echo -e "commit is clean, enabling pipeline for changed images only \n" >&2
        pipelineEnableAll 0
    fi
}

main
