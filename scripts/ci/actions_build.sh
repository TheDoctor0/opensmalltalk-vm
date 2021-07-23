#!/bin/bash
#   - RUNNER_OS can be "Linux", "Windows", or "macOS"
#   - Environment variables can be "exported" to subsequent steps in the 
#     GitHub-Actions workflow as follows:
#        echo "key=${value}" >> $GITHUB_ENV
set -e

if [[ "${RUNNER_OS}" == "Windows" ]]; then
    source ./scripts/ci/actions_prepare_msys.sh
fi

echo "$(cat platforms/Cross/vm/sqSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/vm/sqSCCSVersion.h
echo "$(cat platforms/Cross/plugins/sqPluginsSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/plugins/sqPluginsSCCSVersion.h

[[ -z "${ARCH}" ]] && exit 2
[[ -z "${FLAVOR}" ]] && exit 3

readonly BUILD_PATH="$(pwd)/build.${ARCH}/${FLAVOR}"
echo "BUILD_PATH=${BUILD_PATH}" >> $GITHUB_ENV
readonly PRODUCTS_PATH="$(pwd)/products"
echo "PRODUCTS_PATH=${PRODUCTS_PATH}" >> $GITHUB_ENV

mkdir "${PRODUCTS_PATH}" || true # ensure PRODUCTS_PATH exists

# export COGVREV="$(git describe --tags --always)"
# export COGVDATE="$(git show -s --format=%cd HEAD)"
# export COGVURL="$(git config --get remote.origin.url)"
# export COGVOPTS="-DCOGVREV=\"${COGVREV}\" -DCOGVDATE=\"${COGVDATE// /_}\" -DCOGVURL=\"${COGVURL//\//\\\/}\""


build_Windows() {
    [[ ! -d "${BUILD_PATH}" ]] && exit 100

    pushd "${BUILD_PATH}"
    echo "Skipping bochs plugins..."
    sed -i 's/Bochs.* //g' plugins.ext

    echo "Building OpenSmalltalk VM for Windows..."
    # We cannot zip dbg and ast if we pass -f to just do the full thing...
    # Once this builds, let's pass -A instead of -f and put the full zip (but we should do several zips in the future)
    bash -e ./mvm -f || exit 1
    # zip -r "${output_file}.zip" "./builddbg/vm/" "./buildast/vm/" "./build/vm/"
    mv "./build/vm" "${PRODUCTS_PATH}/" # Move result to PRODUCTS_PATH
    popd
}



if [[ ! $(type -t build_$RUNNER_OS) ]]; then
    echo "Unsupported platform '$(uname -s)'." 1>&2
    exit 99
fi

build_$RUNNER_OS
