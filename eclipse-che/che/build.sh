#!/bin/bash


base_dir=$(cd "$(dirname "$0")"; pwd)
. "${base_dir}"/../build.include


# grab assembly
DIR=$(cd "$(dirname "$0")"; pwd)
if [ ! -d "${DIR}/../../assembly/assembly-main/target" ]; then
  echo "${ERROR}Have you built assembly/assemby-main in ${DIR}/../assembly/assembly-main 'mvn clean install'?"
  exit 2
fi

# Use of folder
BUILD_ASSEMBLY_DIR=$(echo "${DIR}"/../../assembly/assembly-main/target/eclipse-che-*/eclipse-che-*/)
LOCAL_ASSEMBLY_DIR="${DIR}"/eclipse-che

if [ -d "${LOCAL_ASSEMBLY_DIR}" ]; then
  rm -r "${LOCAL_ASSEMBLY_DIR}"
fi

echo "Copying assembly ${BUILD_ASSEMBLY_DIR} --> ${LOCAL_ASSEMBLY_DIR}"
cp -r "${BUILD_ASSEMBLY_DIR}" "${LOCAL_ASSEMBLY_DIR}"

init --name:server "$@"
build

#cleanUp
rm -rf ${DIR}/eclipse-che

