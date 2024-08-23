#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy
# Version       : v1.31.0
# Source repo   : https://github.com/envoyproxy/envoy/
# Tested on     : UBI 8.7
# Language      : C++
# Travis-Check  : False
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
SCRIPT_PACKAGE_VERSION=v1.31.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
SCRIPT_PACKAGE_VERSION_WO_LEADING_V="${SCRIPT_PACKAGE_VERSION:1}"

#Install centos repos
dnf -y install \
	http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
	http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo
dnf install -y epel-release

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
    ninja-build \
    aspell \
    aspell-en \
    sudo

#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
scriptdir=$(dirname $(realpath $0))
wdir=$(pwd)
export ENVOY_BIN=$wdir/envoy/envoy-static
export ENVOY_ZIP=$wdir/envoy/envoy-static_${PACKAGE_VERSION}_UBI8.7.zip

#Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply $scriptdir/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION_WO_LEADING_V}.patch
BAZEL_VERSION=$(cat .bazelversion)

# Build and setup bazel
cd $wdir
if [ -z "$(ls -A $wdir/bazel)" ]; then
	mkdir bazel
	cd bazel
	wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
	unzip bazel-${BAZEL_VERSION}-dist.zip
	rm -rf bazel-${BAZEL_VERSION}-dist.zip
	./compile.sh
fi
export PATH=$PATH:$wdir/bazel/output

#Setup clang
cd $wdir
if [ -z "$(ls -A $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4)" ]; then
	wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
	tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
	rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
fi

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
#bazel test --config=clang --config=libc++ --test_timeout=1000 --cxxopt=-fpermissive --define=wasm=disabled //test/... --cache_test_results=no || true

#Conclude
echo "Build successful!"
echo "Envoy binary available at [$ENVOY_BIN]"
echo "Redistributable zip available at [$ENVOY_ZIP]"

