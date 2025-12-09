#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy
# Version       : v1.29.3
# Source repo   : https://github.com/envoyproxy/envoy/
# Tested on     : UBI 8.7
# Language      : C++
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=envoy
PACKAGE_ORG=envoyproxy
SCRIPT_PACKAGE_VERSION=v1.29.3
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
SCRIPT_PACKAGE_VERSION_WO_LEADING_V="${SCRIPT_PACKAGE_VERSION:1}"

#Install dependencies
yum install -y \
    cmake \
    libatomic \
    libstdc++ \
    libstdc++-static \
    libtool \
    lld \
    patch \
    python3-pip \
    openssl-devel \
    libffi-devel \
    unzip \
    wget \
    zip \
    java-11-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    rust \
    cargo \
    diffutils \
    sudo

sudo rpm -ivh https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-0.60.6.1-22.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-en-2017.08.24-2.el8.ppc64le.rpm

#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
scriptdir=$(dirname $(realpath $0))
wdir=/home/envoy
export ENVOY_BIN=$wdir/envoy/envoy-static
export ENVOY_ZIP=$wdir/envoy/envoy-static_${PACKAGE_VERSION}_UBI8.7.zip

#Find bazel version
wget https://raw.githubusercontent.com/${PACKAGE_ORG}/${PACKAGE_NAME}/${PACKAGE_VERSION}/.bazelversion
BAZEL_VERSION=$(cat .bazelversion)
rm -rf .bazelversion

useradd envoy
sudo -u envoy -- bash <<EOF
set -ex

#Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply $scriptdir/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION_WO_LEADING_V}.patch

# Build and setup bazel
cd $wdir
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
rm -rf bazel-${BAZEL_VERSION}-dist.zip
./compile.sh
export PATH=$PATH:$wdir/bazel/output

#Setup clang
cd $wdir
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz

#Build Envoy
cd $wdir/${PACKAGE_NAME}
bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/
ret=0
bazel build -c opt --config=libc++ envoy --config=clang --define=wasm=disabled --cxxopt=-fpermissive || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi

#Prepare binary for distribution
cp $wdir/envoy/bazel-bin/source/exe/envoy-static $ENVOY_BIN
chmod -R 755 $wdir/envoy
strip -s $ENVOY_BIN
zip $ENVOY_ZIP envoy-static

# Smoke test
$ENVOY_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Smoke test failed."
	exit 2
fi

#Run tests (take several hours to execute, hence disabling by default)
#Some tests might fail because of issues with the tests themselves rather than envoy
#bazel test --config=clang --config=libc++ --test_timeout=2000 --cxxopt=-fpermissive --define=wasm=disabled //test/... --cache_test_results=no || true
EOF

#Conclude
echo "Build successful!"
echo "Envoy binary available at [$ENVOY_BIN]"
echo "Redistributable zip available at [$ENVOY_ZIP]"

