#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : envoy
# Version       : v1.25.3
# Source repo   : https://github.com/envoyproxy/envoy/
# Tested on     : UBI 8.4
# Language      : C++
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>, Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=envoy
PACKAGE_VERSION=${1:-1.25.3}
PACKAGE_URL=https://github.com/envoyproxy/envoy/

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
    binutils

rpm -ivh https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-0.60.6.1-22.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-en-2017.08.24-2.el8.ppc64le.rpm

wdir=`pwd`
#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

PYTHON_VERSION=3.10.2

#Install Python from source
if [ -z "$(ls -A $wdir/Python-${PYTHON_VERSION})" ]; then
	wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
	tar xzf Python-${PYTHON_VERSION}.tgz
	rm -rf Python-${PYTHON_VERSION}.tgz 
	cd Python-${PYTHON_VERSION}
	./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
	make -j ${nproc} 
else
	cd Python-${PYTHON_VERSION}
fi
make altinstall
ln -sf $(which python3.10) /usr/bin/python3
ln -sf $(which pip3.10) /usr/bin/pip3
python3 -V && pip3 -V


# Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION}
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
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz


#Build Envoy
cd $wdir/${PACKAGE_NAME}
git apply ../${PACKAGE_NAME}_${PACKAGE_VERSION}.patch
bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/
bazel build -c opt envoy --config=clang --cxxopt=-fpermissive
ENVOY_BIN=$wdir/envoy/bazel-bin/source/exe/envoy-static

#Prepare binary for distribution
strip -s $ENVOY_BIN
cp $ENVOY_BIN $wdir/envoy/
export ENVOY_BIN=$wdir/envoy/envoy-static
export ENVOY_ZIP=$wdir/envoy/envoy-static_${PACKAGE_VERSION}_UBI8.4.zip
zip $ENVOY_ZIP $ENVOY_BIN

# Smoke test
$ENVOY_BIN --version

#Run tests (take several hours to execute, hence disabling by default)
#Some tests might fail because of issues with the tests themselves rather than envoy
#bazel test --config=clang --test_timeout=9000 --cxxopt=-fpermissive --define=wasm=disabled //test/... --cache_test_results=no --//source/extensions/filters/common/lua:moonjit=1 || true

#Conclude
echo "Build successful!"
echo "Envoy binary available at [$ENVOY_BIN]"
echo "Redistributable zip available at [$ENVOY_ZIP]"
