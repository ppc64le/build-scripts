#!/bin/bash
set -euo pipefail

SRC_DIR=`cd \`dirname ${0}\` && pwd`
TARGET_DIR=${1}
TARGET_COMPONENT=${2}
TARGET_VERSION=${3}

echo "Applying patch for ${TARGET_COMPONENT} version ${TARGET_VERSION} to ${TARGET_DIR}"

cd ${TARGET_DIR}
PATCHES_DIR="${SRC_DIR}/${TARGET_COMPONENT}"
if [ -d ${PATCHES_DIR}/${TARGET_VERSION} ]; then
  PATCHES_DIR=${PATCHES_DIR}/${TARGET_VERSION}
fi
for PATCH in `ls -1 ${PATCHES_DIR}/*.p`; do
  echo "  Applying path ${PATCH}"
  patch -p 1 -i ${PATCH}
done
for SCRIPT in `ls -1 ${PATCHES_DIR}/*.sh`; do
  echo "  Applying script ${SCRIPT}"
  chmod +x ${SCRIPT}
  ${SCRIPT}
done

echo "Done"