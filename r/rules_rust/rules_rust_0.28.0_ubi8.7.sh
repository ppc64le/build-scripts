#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : rules_rust
# Version       : v0.28.0
# Source repo   : https://github.com/bazelbuild/rules_rust
# Tested on     : UBI 8.7
# Language      : Rust
# Ci-Check  : True
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

PACKAGE_NAME=rules_rust
PACKAGE_VERSION=${1:-0.28.0}
PACKAGE_URL=https://github.com/bazelbuild/${PACKAGE_NAME}
PYTHON_VERSION=3.10.2
BAZEL_VERSION=6.3.0
SCRIPT_PATH=$(dirname $(realpath $0))
wdir=`pwd`

#Install Centos repos and dependencies
dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo
dnf install -y \
    automake \
    diffutils \
    gcc \
    gcc-c++ \
    git \
    libyaml-devel \
    make \
    patch \
    perl \
    protobuf-devel \
    unzip \
    valgrind \
    valgrind-devel \
    zlib-devel \
    wget \
    java-11-openjdk-devel


#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

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


#Download source code
if [ -z "$(ls -A $wdir/${PACKAGE_NAME})" ]; then
	cd $wdir
	git clone ${PACKAGE_URL}
	cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
	git apply $SCRIPT_PATH/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch
fi

# Build and setup bazel
if [ -z "$(ls -A $wdir/bazel)" ]; then
	cd $wdir
        mkdir bazel
        cd bazel
        wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
        unzip bazel-${BAZEL_VERSION}-dist.zip
        rm -rf bazel-${BAZEL_VERSION}-dist.zip
        ./compile.sh
fi
export PATH=$PATH:$wdir/bazel/output

#Build
cd $wdir/${PACKAGE_NAME}
ret=0
bazel build //... || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi

#Test
bazel test //... || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "Tests fail."
	exit 2
fi

#Conclude
set +ex
echo "Build and tests successful!"
