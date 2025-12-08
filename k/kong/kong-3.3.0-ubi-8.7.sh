#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : kong
# Version	    : 3.3.0
# Source repo	: https://github.com/kong/kong
# Tested on	    : UBI 8.7
# Language      : Rust
# Ci-Check  : true
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

PACKAGE_NAME=kong
PACKAGE_VERSION=${1:-3.3.0}
PACKAGE_URL=https://github.com/kong/kong/
PYTHON_VERSION=3.10.2

#Install dependencies
dnf -y install \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo

dnf install -y \
    automake \
    gcc \
    gcc-c++ \
    git \
    libyaml-devel \
    make \
    patch \
    perl \
    perl-IPC-Cmd \
    protobuf-devel \
    zip unzip \
    valgrind \
    valgrind-devel \
    zlib-devel \
    wget \
    cmake \
    java-11-openjdk-devel \
    tzdata-java \
    curl \
    file

wdir=`pwd`
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
       ./configure --enable-shared --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
       make -j ${nproc}
else
       cd Python-${PYTHON_VERSION}
fi
make altinstall
ln -sf $(which python3.10) /usr/bin/python3
ln -sf $(which pip3.10) /usr/bin/pip3
ln -s /usr/share/pyshared/lsb_release.py /usr/local/lib/python3.10/site-packages/lsb_release.py
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$wdir/Python-3.10.2/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
python3 -V && pip3 -V


#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
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

#Install rust and cross
curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
cargo install cross --version 0.2.1

#Install Golang
cd $wdir
wget https://go.dev/dl/go1.20.5.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.5.linux-ppc64le.tar.gz
rm -rf go1.20.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
go install github.com/go-task/task/v3/cmd/task@latest
export PATH=$PATH:$HOME/go/bin

#Patch and build  Kong
cd $wdir/${PACKAGE_NAME}
git apply $wdir/kong-${PACKAGE_VERSION}.patch
make build-release > /dev/null 2>&1 || true

#Patch rules_rust
pushd $(find $HOME/.cache/bazel -name rules_rust) 
git apply $wdir/kong-${PACKAGE_VERSION}-rules_rust.patch

#Build cargo-bazel native binary
cd crate_universe
cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu
export CARGO_BAZEL_GENERATOR_URL=file://$(pwd)/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel
echo "cargo-bazel build successful!"
popd

#Build nfpm native binary
cd $wdir
git clone https://github.com/goreleaser/nfpm.git
cd nfpm && git checkout v2.30.1
task setup
task build
NFPM_BIN=$(pwd)/nfpm

#Build kong .deb package
echo "Building Kong debian package..."
cd $wdir/${PACKAGE_NAME}
make package/deb  > /dev/null 2>&1 || true
cp -f $NFPM_BIN $(find $HOME/.cache/bazel -type d -name nfpm)
make package/rpm
cp $(find / -name kong.el8.ppc64le.rpm) $wdir
export KONG_RPM=$wdir/kong.el8.ppc64le.rpm

#Conclude
set +ex
echo "Build successful!"
echo "Kong RPM package available at [$KONG_RPM]"
