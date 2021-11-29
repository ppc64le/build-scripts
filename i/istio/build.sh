#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package        : istio
# Version        : 1.12.0
# Source repo    : https://github.com/istio/istio.git
# Tested on      : Ubuntu 20.04.2 LTS
# Script License : Apache License, Version 2 or later
# Maintainer     : Matthieu Sarter <matthieu.sarter@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -euo pipefail
set -x

VERSION=${1:-1.12.0}
SRC_DIR=`cd \`dirname ${0}\` && pwd`

HUB=${HUB:-localhost:5000/istio}
WORK_DIR=${WORK_DIR:-`mktemp -d`}
BUILD_TOOLS=${BUILD_TOOLS:-yes}
PUBLISH_TOOLS=${PUBLISH_TOOLS:-yes}
BUILD_PROXY=${BUILD_PROXY:-yes}
BUILD_IMAGES=${BUILD_IMAGES:-yes}
PUBLISH_IMAGES=${PUBLISH_IMAGES:-yes}
BUILD_PACKAGE=${BUILD_PACKAGE:-yes}
DEBUG=${DEBUG:-yes}

# Builds istio-<version>.tar.gz and istioctl-<version>.tar.gz for ppc64le
function build_archives() {
  # Build istioctl
  make TEMP_ROOT=${WORK_DIR} VERSION=${VERSION} cleanup.istio
  make TEMP_ROOT=${WORK_DIR} VERSION=${VERSION} clone.istio
  cd ${WORK_DIR}/istio
  echo "Building istioctl"
  IMAGE_VERSION="master-latest"
  if [ "${VERSION}" != "master" ]; then
    IMAGE_VERSION="release-"`echo ${VERSION} | cut -d . -f 1`"."`echo ${VERSION} | cut -d . -f 2`"-latest"
  fi
  make IMG=${HUB}/build-tools:${IMAGE_VERSION} /work/out/linux_ppc64le/release/istioctl-linux-ppc64le

  # Build archives
  cd ${WORK_DIR}
  ARCHIVE_DIR=istio-${VERSION}
  ARCHIVE_FILE="${ARCHIVE_DIR}-linux-ppc64le.tar.gz"
  echo "Building ${ARCHIVE_FILE}"
  mkdir ${ARCHIVE_DIR}
  cp istio/LICENSE ${ARCHIVE_DIR}
  cp istio/README.md ${ARCHIVE_DIR}
  mkdir -p ${ARCHIVE_DIR}/tools/certs
  cp istio/tools/certs/README.md ${ARCHIVE_DIR}/tools/certs
  cp istio/tools/certs/common.mk ${ARCHIVE_DIR}/tools/certs
  cp istio/tools/certs/Makefile* ${ARCHIVE_DIR}/tools/certs
  cp -r istio/samples ${ARCHIVE_DIR}/samples
  find ${ARCHIVE_DIR}/samples -type f | grep -v "yaml\|md\|sh\|txt\|pem\|conf\|tpl\|json\|Makefile" | xargs rm
  mkdir ${ARCHIVE_DIR}/manifests
  cp -r istio/manifests/charts ${ARCHIVE_DIR}/manifests/charts
  cp -r istio/manifests/examples ${ARCHIVE_DIR}/manifests/examples
  cp -r istio/manifests/profiles ${ARCHIVE_DIR}/manifests/profiles
  cp -r istio/operator/samples ${ARCHIVE_DIR}/samples/operator
  mkdir ${ARCHIVE_DIR}/bin
  cp istio/out/linux_ppc64le/release/istioctl-linux-ppc64le ${ARCHIVE_DIR}/bin/istioctl
  tar czf ${SRC_DIR}/${ARCHIVE_FILE} ${ARCHIVE_DIR}
  echo "${SRC_DIR}/${ARCHIVE_FILE} built"
  tar czf ${SRC_DIR}/istioctl-${VERSION}.tar.gz -C ${ARCHIVE_DIR}/bin istioctl
  echo "${SRC_DIR}/istioctl-${VERSION}.tar.gz built"
}

# Extracts the envoy wasm extensions from the amd64 proxy image
function get_envoy_extensions() {
  DOCKER_CREATE="docker create --platform=linux/amd64 --name tmp-istio-proxy istio/proxyv2"
  ${DOCKER_CREATE}:${VERSION} || ${DOCKER_CREATE}:latest
  docker cp tmp-istio-proxy:/etc/istio/extensions ${WORK_DIR}/envoy-linux-ppc64le
  docker rm tmp-istio-proxy
}

function cleanup() {
  rm -rf ${WORK_DIR}
}

function main() {
  if [[ "${BUILD_TOOLS}" == "yes" ]]; then
    make TEMP_ROOT=${WORK_DIR} HUB=${HUB} VERSION=${VERSION} PUBLISH_IMAGES=${PUBLISH_TOOLS} dockerx.build-tools
  fi
  if [[ "${BUILD_PROXY}" == "yes" ]]; then
    export BAZEL_WORK_DIR=${WORK_DIR}/bazel
    mkdir -p ${BAZEL_WORK_DIR}/cache
    rm -rf ${BAZEL_WORK_DIR}/rules_docker
    # Get Bazel Docker rules from PR1918. With this PR, go puller will be built at runtime, instead of using a prebuilt
    # binary, that is not available for ppc64le
    git clone https://github.com/bazelbuild/rules_docker.git ${BAZEL_WORK_DIR}/rules_docker
    (
      cd ${BAZEL_WORK_DIR}/rules_docker
      git fetch origin pull/1918/head:build_puller_pusher
      git checkout build_puller_pusher
    )
    make TEMP_ROOT=${WORK_DIR} HUB=${HUB} VERSION=${VERSION} PULL_TOOLS=no build.envoy
  fi
  if [[ "${BUILD_IMAGES}" == "yes" ]]; then
    get_envoy_extensions
    make TEMP_ROOT=${WORK_DIR} HUB=${HUB} VERSION=${VERSION} PUBLISH_IMAGES=${PUBLISH_IMAGES} PULL_TOOLS=no build.istio
    make TEMP_ROOT=${WORK_DIR} HUB=${HUB} VERSION=${VERSION} PUBLISH_IMAGES=${PUBLISH_IMAGES} PULL_TOOLS=no dockerx.istio-images
  fi
  if [[ "${BUILD_PACKAGE}" == "yes" ]]; then
    build_archives
  fi
  if [[ "${DEBUG}" == "no" ]]; then
    cleanup
  fi
}

main | tee -a /tmp/istio-build-`date +%Y%m%d_%H%M%S`.log