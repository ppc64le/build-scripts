#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: osquery
# Version	: 5.18.1
# Source repo	: https://github.com/osquery/osquery
# Tested on	: UBI 9.5
# Language      : C++
# Travis-Check  : false 
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=5.18.1
PACKAGE_NAME=osquery
PACKAGE_ORG=osquery
PACKAGE_VERSION=${SCRIPT_PACKAGE_VERSION}
PACKAGE_URL=https://github.com/$PACKAGE_ORG/$PACKAGE_NAME.git
CMAKE_VERSION=3.21.4
OSQ_TOOLCHAIN_VERSION=1.1.0
export CT_ALLOW_BUILD_AS_ROOT=y
export CT_ALLOW_BUILD_AS_ROOT_SURE=y
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1

################################
#Parse CLI Arguments
################################
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done


################################
#Install repos and deps
################################
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
rpm -e --nodeps openssl-fips-provider-so
yum install gcc gcc-c++ glibc-static libstdc++-static automake autoconf gettext bison flex unzip help2man libtool ncurses-devel make ninja-build patch gawk wget git texinfo xz python-devel pip openssl-devel bzip2 file diffutils perl-IPC-Cmd perl-FindBin -y
cp /usr/lib64/libncurses.so.6 /usr/lib64/libncurses.so.5
pip install psutil timeout_decorator docker pexpect thrift

################################
#Build and install cmake
################################
cd ${BUILD_HOME}
if [ -z "$(ls -A ${BUILD_HOME}/cmake-${CMAKE_VERSION})" ]; then
        wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
        tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
        rm -rf cmake-${CMAKE_VERSION}.tar.gz
        cd cmake-${CMAKE_VERSION}
        ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON
else
        cd cmake-${CMAKE_VERSION}
fi
make install -j$(nproc)
export PATH=/usr/local/cmake/bin:$PATH
cmake --version

################################
#Build osquery toolchain
################################
cd ${BUILD_HOME}
if [ -z "$(ls -A ${BUILD_HOME}/osquery-toolchain)" ]; then
	git clone https://github.com/osquery/osquery-toolchain
	cd osquery-toolchain
	git checkout $OSQ_TOOLCHAIN_VERSION
	git apply $SCRIPT_PATH/osquery-toolchain_${OSQ_TOOLCHAIN_VERSION}.patch
else
        cd osquery-toolchain
fi
mkdir -p $HOME/src
./build.sh ${BUILD_HOME}/osquery-toolchain/osquery-toolchain

#################################
#Get repo and apply patches
################################
cd ${BUILD_HOME}
git clone --recurse-submodules $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
git apply $SCRIPT_PATH/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch
pushd libraries/cmake/source/ebpfpub/src/libraries/ebpf-common/src
git apply $SCRIPT_PATH/ebpf-common_${SCRIPT_PACKAGE_VERSION}.patch
popd
pushd libraries/cmake/source/libaudit/src
git apply $SCRIPT_PATH/libaudit_${SCRIPT_PACKAGE_VERSION}.patch
popd
pushd libraries/cmake/source/sqlite/src
git apply $SCRIPT_PATH/sqlite_${SCRIPT_PACKAGE_VERSION}.patch
popd
pushd osquery/experimental/experiments/linuxevents/libraries/linuxevents/src/libraries/ebpf-common/src
git apply $SCRIPT_PATH/ebpf-common_${SCRIPT_PACKAGE_VERSION}.patch
popd

################################
#Build
################################
mkdir build && cd build
ret=0
cmake -DOSQUERY_TOOLCHAIN_SYSROOT=$BUILD_HOME/osquery-toolchain/osquery-toolchain/final/sysroot -DOSQUERY_BUILD_BPF=Off -DOSQUERY_BUILD_TESTS=ON .. || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi
cmake --build . -j$(nproc) || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi


################################
#Install
################################
make install || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Install Failed ------------------"
        exit 1
fi


################################
#Skip Tests?
################################
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "Complete: Build and install successful! Tests skipped."
	echo "After install intructions available at: https://osquery.readthedocs.io/en/latest/installation/install-linux/"
        exit 0
fi


################################
#Test
################################
cmake --build . --target test || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
        exit 2
fi



################################
#Conclude
################################
set +ex
echo "Complete: Build, install and test successful!"
echo "After install intructions available at: https://osquery.readthedocs.io/en/latest/installation/install-linux/"
echo "Note: The following six tests are disabled as they are in parity with x86_64:"
echo "    osquery_tables_system_linux_tests-test"
echo "    osquery_core_tests_permissionstests-test"
echo "    osquery_filesystem_filesystemtests-test"
echo "    osquery_events_tests_linuxtests-test"
echo "    tools_tests_testfschangestable"
echo "    tests_integration_tables-test"

