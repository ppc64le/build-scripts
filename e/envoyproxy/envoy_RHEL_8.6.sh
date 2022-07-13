#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : envoy
# Version        : v2.2
# Source repo    : https://github.com/maistra/envoy.git
# Tested on      : RHEL 8.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Nishikant Thorat <Nishikant.Thorat@ibm.com>
# Travis-Check   : True
# Language       : go
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# Adding repos, to fix travis failures
#
yum install yum-utils -y

for file in mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/ mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/
do
  yum-config-manager --add-repo http://${file}
  repo=$(echo $files | sed "s#/#_#g")
  echo "gpgcheck=0" >>  /etc/yum.repos.d/${repo}.repo
done

# 
# Install required packages 
#
yum install -y git python3 libtool automake curl cmake openssl-devel npm openssl clang
# yum install -y libstdc++-devel-8.5.0-4.el8_5 
yum install -y gcc-c++-8.5.0-4.el8_5 gcc-8.5.0-4.el8_5
yum install -y perl lld patch
yum install -y java-11-openjdk-devel
rpm -ihv https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/libstdc++-static-8.5.0-4.el8_5.ppc64le.rpm
# 
# Install ninja v1.8.2
#
mkdir ~/istio_build/
export SOURCE_ROOT=~/istio_build/
cd $SOURCE_ROOT
git clone https://github.com/ninja-build/ninja.git -b v1.8.2 
cd ninja
yum install -y python3
ln -s /usr/bin/python3 /usr/bin/python
./configure.py --bootstrap
ln -sf $SOURCE_ROOT/ninja/ninja /usr/local/bin/ninja
#
# Install gn
#
cd $SOURCE_ROOT
git clone https://gn.googlesource.com/gn
cd gn
python build/gen.py
ninja -C out
export PATH=/root/istio_build/gn/out:$PATH
#
# Build and install llvm for clang v13
#
cd $SOURCE_ROOT
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-13.0.1
cd $SOURCE_ROOT
mkdir -p llvm_build
cd llvm_build
cmake3 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm-project/llvm
ninja -j$(nproc)
export PATH=/root/istio_build/llvm_build/bin:$PATH
export CC=/root/istio_build/llvm_build/bin/clang
export CXX=/root/istio_build/llvm_build/bin/clang++
#
# Install GO
#
cd $SOURCE_ROOT
yum install -y curl
curl -O https://dl.google.com/go/go1.17.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.17.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
which go
go version
#
# Install bazel v4.1.0
#
rpm -ihv https://oplab9.parqtec.unicamp.br/pub/repository/rpm/ppc64le/bazel/bazel-4.1.0-1.ppc64le.rpm
#
# Build envoy maistra 2.2
#
cd $SOURCE_ROOT
git clone https://github.com/maistra/envoy.git
cd envoy/
git checkout maistra-2.2
bazel clean
bazel build -c opt //source/exe:envoy-static --sandbox_debug --verbose_failures --copt "-w" --copt "-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1" --cxxopt=-Wimplicit-fallthrough=0 --cxxopt=-Wno-error=type-limits --config=ppc64le --config=clang  --//bazel:http3=false --local_ram_resources=12288 --local_cpu_resources=6 --jobs=3


