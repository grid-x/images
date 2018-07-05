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

ROOT_PIPELINE_CONFIG=.buildkite/pipeline.config.json
export IMAGE_PIPELINE_CONFIG=pipeline.config.json
export IMAGES_ENABLED=/tmp/images_enabled
export PIPELINE_FINAL=/tmp/pipeline_final
export STEPS_DIR=.buildkite/steps

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
    if [ ! -f "${IMAGES_DIR}/${IMAGE_ID}/${IMAGE_PIPELINE_CONFIG}" ]; then
        printf "%-40s \e[31m⚠ need rebuild - config missing\e[39m\n" $1 >&2
    else
        printf "%-40s \e[33m✖ need rebuild\e[39m\n" $1 >&2
        echo "${IMAGE_ID}" >> ${IMAGES_ENABLED}
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
        printf "%-40s \e[32m✓ up to date\e[39m\n" ${IMAGE_ID} >&2
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
    # init temporary files
    rm ${IMAGES_ENABLED} 2> /dev/null || true
    rm ${PIPELINE_FINAL} 2> /dev/null || true
    touch ${PIPELINE_FINAL}

    # enable images if needed
    echo "+++ Checking images" >&2
    if commitIsDirty; then
        printf "\e[33mcommit is dirty, enabling pipeline for all images\e[39m\n" >&2
        pipelineEnableAll 1
    else
        printf "\e[32mcommit is clean, enabling pipeline for changed images only\e[39m\n" >&2
        pipelineEnableAll 0
    fi

    # iterate over build groups (e.g. build, test, ...)
    for GROUP in $(jq -r '.groups[].id' ${ROOT_PIPELINE_CONFIG}); do
        echo -e "\n+++ $GROUP group" >& 2
        # iterate over images that need to be rebuilt
        while read IMAGE_NAME; do
            # get step from image pipeline config
            STEP=$(jq -r ".steps.${GROUP}" ${IMAGES_DIR}/${IMAGE_NAME}/${IMAGE_PIPELINE_CONFIG})
            if [ "$STEP" == "null" ]; then
                printf "%-40s \e[33m✖ no step defined\e[39m\n" ${IMAGE_NAME}>&2
                continue
            fi
            printf "%-40s \e[32m%s\e[39m\n" ${IMAGE_NAME} ${STEP} >&2
            # concat steps into final pipeline
            jq -n \
                --arg image_name "${IMAGE_NAME}" \
                --slurpfile steps "${STEPS_DIR}/${STEP}.json" \
                '$steps[] | map(.env.IMAGE_NAME=$image_name | .name=$image_name + " " + .name) as $steps | {"steps": $steps }' ${PIPELINE_FINAL}

            printf "%-40s \e[32m✓ using step %s\e[39m\n" ${IMAGE_NAME} ${STEP} >&2
        done <${IMAGES_ENABLED}
    done

    # pipe final config to buildkite-agent upload
    cat ${PIPELINE_FINAL}
}

main
