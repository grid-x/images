#!/usr/bin/env bash
set -euo pipefail

#
#  *Dynamic Buildkite Pipeline*
#
#   DESCRIPTION:
#     Generates a pipeline for images inside image folder,
#     for usage with Buildkite.
#
#     The pipeline is split up into job groups, which run sequentially.
#     Individual images use predifined steps for each job group,
#     as set up in JSON-encoded config files.
#
#     Diffs current commit to previous to decide
#     which images need to be rebuilt.
#     If there are changes outside the images folder,
#     fall back to rebuilding all images.
#
#     Individual images define a JSON-formatted config file,
#
#   USAGE:
#     .buildkite/pipeline.sh && buildkite-agent pipeline upload
#


ROOT_PIPELINE_CONFIG=.buildkite/pipeline.config.json # defines job groups
export STEPS_DIR=.buildkite/steps                    # steps available for use in job group
export IMAGE_PIPELINE_CONFIG=pipeline.config.json    # image association: job group -> step

export IMAGES_ENABLED=/tmp/images_enabled
export PIPELINE_OUT=.buildkite/pipeline.json
export PIPELINE_TMP=/tmp/pipeline.json


# diff current commit to last
commitGetDiff() {
    git diff ${BUILDKITE_COMMIT}..master --name-only
}
export -f commitGetDiff

# check for changes outside images folder
commitIsDirty() {
    commitGetDiff | grep -qcv ${IMAGES_DIR}
}

# check for changes inside specific image folder
imageIsDirty() {
    IMAGE_ID="$1"
    commitGetDiff | grep -qc "^${IMAGES_DIR}/${IMAGE_ID}"
}
export -f imageIsDirty

# if a specific image needs a rebuild, enable its pipeline
imageEnableMaybe() {
    IMAGE_ID="$1"
    COMMIT_IS_DIRTY="$2"
    if [ -f ${IMAGES_DIR}/${IMAGE_ID}/.ignore ]; then
        printf "%-40s \e[33m− ignored\e[39m\n" $1
    elif [ "${COMMIT_IS_DIRTY}" -eq 1 ] || imageIsDirty ${IMAGE_ID}; then
        if [ ! -f "${IMAGES_DIR}/${IMAGE_ID}/${IMAGE_PIPELINE_CONFIG}" ]; then
            printf "%-40s \e[31m⚠ need rebuild - config missing\e[39m\n" $1
        else
            printf "%-40s \e[33m✖ need rebuild\e[39m\n" $1
            echo "${IMAGE_ID}" >> ${IMAGES_ENABLED}
        fi
    else
        printf "%-40s \e[32m✓ up to date\e[39m\n" ${IMAGE_ID}
    fi
}
export -f imageEnableMaybe

main() {
    # init temporary files
    rm ${IMAGES_ENABLED} 2> /dev/null || true
    rm ${PIPELINE_OUT}   2> /dev/null || true
    rm ${PIPELINE_TMP}   2> /dev/null || true

    jq -n '{"steps": []}' > ${PIPELINE_OUT}

    echo "+++ Checking images"

    # dirty commit overwrites clean image state
    if commitIsDirty; then
        printf "\e[33mcommit is dirty, enabling pipeline for all images\e[39m\n"
        COMMIT_IS_DIRTY=1
    else
        printf "\e[32mcommit is clean, enabling pipeline for changed images only\e[39m\n"
        COMMIT_IS_DIRTY=0
    fi

    # iterate over images and enable suitable
    find ./${IMAGES_DIR} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | \
        xargs -n1 -I{} bash -c "imageEnableMaybe {} ${COMMIT_IS_DIRTY}"

    # iterate over job groups (e.g. build, test, ...)
    for GROUP in $(jq -r '.job_groups[].id' ${ROOT_PIPELINE_CONFIG}); do
        echo -e "\n+++ Group \"$GROUP\""

        # add wait step before the next group
        # this produces no output for the first iteration
        # due to pipeline being empty.
        # HACK: in-place editing does not work with jq
        jq '.steps[.steps | length] = "wait"' ${PIPELINE_OUT} > ${PIPELINE_TMP}
        cp ${PIPELINE_TMP} ${PIPELINE_OUT}

        # iterate over images that need to be rebuilt
        while read IMAGE_NAME; do
            # get step from image pipeline config
            STEP=$(jq -r ".steps.${GROUP}.id" ${IMAGES_DIR}/${IMAGE_NAME}/${IMAGE_PIPELINE_CONFIG})
            if [ "$STEP" == "null" ]; then
                printf "%-40s \e[33m✖ no step defined\e[39m\n" ${IMAGE_NAME}
                continue
            fi

            # step was not found, fatal error
            # TODO: support image-specific custom steps
            if [ ! -f ${STEPS_DIR}/${STEP}.json ]; then
                printf "%-40s \e[31m⚠ step %s does not exist\e[39m\n" ${IMAGE_NAME} ${STEP}
                exit 1
            fi

            # get step specific env variables
            STEP_ENV=$(jq -c ".steps.${GROUP}.env" ${IMAGES_DIR}/${IMAGE_NAME}/${IMAGE_PIPELINE_CONFIG})

            # concat steps onto final pipeline,
            # inject step specific env variables,
            # inject `IMAGE_NAME` env variable,
            # prepend image name to step name,
            # save in `PIPELINE_OUT`.
            # HACK: in-place editing does not work with jq
            jq \
                --arg image_name "${IMAGE_NAME}" \
                --argjson step_env "${STEP_ENV}" \
                --slurpfile steps "${STEPS_DIR}/${STEP}.json" \
                'reduce $steps[] as $step (.; .steps[.steps | length] = ($step | map(.env=$step_env) | map(.env.IMAGE_NAME=$image_name | .name=$image_name + " " + .name))) | .steps = (.steps | flatten)' \
                "${PIPELINE_OUT}" \
                > ${PIPELINE_TMP}
            cp ${PIPELINE_TMP} ${PIPELINE_OUT}

            printf "%-40s \e[32m✓ using step '%s'\e[39m\n" ${IMAGE_NAME} ${STEP}
        done <${IMAGES_ENABLED}
    done

    # display final config for debug purpose
    echo -e "\n--- Config built"
    jq '.' ${PIPELINE_OUT}
}

main
