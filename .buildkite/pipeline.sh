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
        bk_annotate 'images' "<tr><td>-</td><td>${IMAGE_ID}</td><td>Ignored</td></tr>" 'info'
    elif [ "${COMMIT_IS_DIRTY}" -eq 1 ] || imageIsDirty ${IMAGE_ID}; then
        if [ ! -f "${IMAGES_DIR}/${IMAGE_ID}/${IMAGE_PIPELINE_CONFIG}" ]; then
            printf "%-40s \e[31m⚠ need rebuild - config missing\e[39m\n" $1
            bk_annotate 'images' "<tr><td>⚠</td><td>${IMAGE_ID}</td><td>Need rebuild - config missing</td></tr>" 'error'
        else
            printf "%-40s \e[33m✖ need rebuild\e[39m\n" $1
            bk_annotate 'images' "<tr><td>✖</td><td>${IMAGE_ID}</td><td>Need rebuild</td></tr>" 'warning'
            echo "${IMAGE_ID}" >> ${IMAGES_ENABLED}
        fi
    else
        printf "%-40s \e[32m✓ up to date\e[39m\n" ${IMAGE_ID}
        bk_annotate 'images' "<tr><td>✓</td><td>${IMAGE_ID}</td><td>Up to date</td></tr>" 'success'
    fi
}
export -f imageEnableMaybe

bk_annotate() {
    CONTEXT=${1:-default}
    MESSAGE="$2"
    STYLE=${3:-null}
    if [ "${STYLE}" != "null" ]; then
        buildkite-agent annotate \
        --style "${STYLE}" \
        --context "${CONTEXT}" \
        --append \
        "${MESSAGE}" &> /dev/null
    else
        buildkite-agent annotate \
        --context "${CONTEXT}" \
        --append \
        "${MESSAGE}" &> /dev/null
    fi
}
export -f bk_annotate

main() {
    # init temporary files
    rm ${IMAGES_ENABLED} 2> /dev/null || true
    rm ${PIPELINE_OUT}   2> /dev/null || true
    rm ${PIPELINE_TMP}   2> /dev/null || true

    jq -n '{"steps": []}' > ${PIPELINE_OUT}

    # dirty commit overwrites clean image state
    if commitIsDirty; then
        printf "\e[33mcommit is dirty, enabling pipeline for all images\e[39m\n"
        bk_annotate 'dirty' 'Commit is dirty, enabling pipeline for all images.' 'error'
        COMMIT_IS_DIRTY=1
    else
        printf "\e[32mcommit is clean, enabling pipeline for changed images only\e[39m\n"
        bk_annotate 'dirty' 'Commit is clean, enabling pipeline for changed images only.' 'success'
        COMMIT_IS_DIRTY=0
    fi

    echo "+++ Checking images"
    bk_annotate 'images' '<table><thead><tr><th></th><th>Image</th><th>Status</th></tr></thead>' 'info'

    # iterate over images and enable suitable
    find ./${IMAGES_DIR} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | \
        xargs -n1 -I{} bash -c "imageEnableMaybe {} ${COMMIT_IS_DIRTY}"

    bk_annotate 'images' '</tbody></table>' 'info'

    # iterate over job groups (e.g. build, test, ...)
    for GROUP in $(jq -r '.job_groups[].id' ${ROOT_PIPELINE_CONFIG}); do
        echo -e "\n+++ Group \"$GROUP\""
        bk_annotate "group-${GROUP}" "<h4>Group: ${GROUP}</h4><table><thead><tr><th></th><th>Image</th><th>Status</th></tr></thead><tbody>" 'info'

        GROUP_IS_DIRTY=0

        # add wait step before the next group
        # this produces no output for the first iteration
        # due to pipeline being empty.
        # HACK: in-place editing does not work with jq
        jq '.steps[.steps | length] = "wait"' ${PIPELINE_OUT} > ${PIPELINE_TMP}
        cp ${PIPELINE_TMP} ${PIPELINE_OUT}

        # iterate over images that need to be rebuilt
        while read IMAGE_NAME; do

            # get jobs from image pipeline config
            for JOB in $(jq -c '.[]' "${IMAGES_DIR}/${IMAGE_NAME}/${IMAGE_PIPELINE_CONFIG}"); do

                # optional job name
                JOB_NAME=$(echo "$JOB" | jq -r ".name")
                if [ "${JOB_NAME}" != "null" ]; then
                    FRIENDLY_NAME="${IMAGE_NAME}: ${JOB_NAME}"
                else
                    FRIENDLY_NAME="${IMAGE_NAME}"
                fi

                # get step from image pipeline config
                STEP=$(echo "$JOB" | jq -r ".steps.${GROUP}.id" )
                if [ "$STEP" == "null" ]; then
                    STEP_DIRTY="true"
                    printf "%-40s \e[33m✖ no step defined\e[39m\n" ${FRIENDLY_NAME}
                    bk_annotate "group-${GROUP}" "<tr><td>✖</td><td>${FRIENDLY_NAME}</td><td>No step defined</td></tr>" 'warning'
                    GROUP_IS_DIRTY=1
                    continue
                fi

                # step was not found, fatal error
                # TODO: support image-specific custom steps
                if [ ! -f ${STEPS_DIR}/${STEP}.json ]; then
                    printf "%-40s \e[31m⚠ step %s does not exist\e[39m\n" ${FRIENDLY_NAME} ${STEP}
                    bk_annotate "group-${GROUP}" "<tr><td>⚠</td><td>${FRIENDLY_NAME}</td><td>Step »<b>${STEP}</b>« does not exist</td></tr>" 'error'
                    exit 1
                fi

                # get step specific env variables
                STEP_ENV=$(echo "$JOB" | jq -c ".steps.${GROUP}.env")

                # concat steps onto final pipeline,
                # inject step specific env variables,
                # inject `IMAGE_NAME` env variable,
                # prepend image name to step name,
                # save in `PIPELINE_OUT`.
                # HACK: in-place editing does not work with jq
                jq \
                    --arg friendly_name "${FRIENDLY_NAME}" \
                    --arg image_name "${IMAGE_NAME}" \
                    --argjson step_env "${STEP_ENV}" \
                    --slurpfile steps "${STEPS_DIR}/${STEP}.json" \
                    'reduce $steps[] as $step (.; .steps[.steps | length] = ($step | map(.env=$step_env) | map(.env.IMAGE_NAME=$image_name | .name=$friendly_name + " " + .name))) | .steps = (.steps | flatten)' \
                    "${PIPELINE_OUT}" \
                    > ${PIPELINE_TMP}
                cp ${PIPELINE_TMP} ${PIPELINE_OUT}

                printf "%-40s \e[32m✓ using step '%s'\e[39m\n" "${FRIENDLY_NAME}" ${STEP}
                bk_annotate "group-${GROUP}" "<tr><td>✓</td><td>${FRIENDLY_NAME}</td><td>Using step »<b>${STEP}</b>«</td></tr>" 'success'
                if [ "${STEP_ENV}" != "null" ]; then
                    printf "%40s \e[37m%s\e[39m\n" "" ${STEP_ENV}
                    bk_annotate "group-${GROUP}" "<tr><td></td><td></td><td><code>${STEP_ENV}</code></td></tr>" 'success'
                fi

            done
        done <${IMAGES_ENABLED}

        if [ "${GROUP_IS_DIRTY}" -eq 1 ]; then
            bk_annotate "group-${GROUP}" '</tbody></table>' 'warning'
        else
            bk_annotate "group-${GROUP}" '</tbody></table>' 'success'
        fi

    done

    # display final config for debug purpose
    echo -e "\n--- Config built"
    jq '.' ${PIPELINE_OUT}
}

main
