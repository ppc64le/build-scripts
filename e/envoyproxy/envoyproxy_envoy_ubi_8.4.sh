# ----------------------------------------------------------------------------
#
# Package        : envoy
# Version        : v1.19.1
# Source repo    : https://github.com/envoyproxy/envoy.git
# Tested on      : UBI 8.4
# Script License : Apache License, Version 2 or later
# Maintainer     : Maniraj Deivendran <maniraj.deivendran@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

BUILD_VERSION=v1.19.1

#Install libraries
yum update -y
yum install -y git gcc-c++ python3 libtool automake curl gcc vim cmake openssl-devel npm
cat > /etc/yum.repos.d/centos.repo<<EOF
[local-rhn-server-baseos]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server RPMs
baseurl=http://mirror.centos.org/centos-8/8/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-appstream]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos-8/8/AppStream/\$basearch/os/
enabled=1
gpgcheck=0
EOF
dnf group install -y "Development Tools"
dnf install -y gcc-toolset-9 gcc-toolset-9-gcc gcc-toolset-9-gcc-c++ gcc-toolset-9-libatomic-devel binutils-devel
ln -s /usr/bin/python3 /usr/bin/python

#Set PATH variables
source scl_source enable gcc-toolset-9
source /opt/rh/gcc-toolset-9/enable
export CC=/opt/rh/gcc-toolset-9/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-9/root/usr/bin/g++
export PATH=$PATH:/opt/rh/gcc-toolset-9/root/bin/
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-9/root/usr/lib64:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=/opt/rh/gcc-toolset-9/root/usr/lib/gcc/ppc64le-redhat-linux/9/include/
export CPLUS_INCLUDE_PATH=/opt/rh/gcc-toolset-9/root/usr/lib/gcc/ppc64le-redhat-linux/9/include/

#Install Java
yum install -y java-11-openjdk-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre

mkdir ~/istio_build/
export SOURCE_ROOT=~/istio_build/

#Build ninja
cd $SOURCE_ROOT
git clone git://github.com/ninja-build/ninja.git
cd ninja
git checkout v1.8.2
./configure.py --bootstrap
ln -sf $SOURCE_ROOT/ninja/ninja /usr/local/bin/ninja

cd $SOURCE_ROOT
git clone https://gn.googlesource.com/gn
cd gn
git checkout 992e927e217baa8a74e6e2c5d7417cb65cf24824
python build/gen.py
ninja -C out
ln -sf $SOURCE_ROOT/gn/out/gn /usr/local/bin/gn

#Install Bazel binary
curl -O https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_18.04/bazel_bin_ppc64le_3.7.2
mv bazel_bin_ppc64le_3.7.2 /usr/local/bin/bazel
chmod 755 /usr/local/bin/bazel

#Build Maistra/envoy
cd $SOURCE_ROOT
git clone https://github.com/envoyproxy/envoy.git
cd envoy/
git checkout $BUILD_VERSION

#Assume patch file copied already in root directory.
#Apply patch to resolve "ERROR at //.gn:18:20: Assignment had no effect" issue.
cp /wee8.patch .
git apply wee8.patch

bazel build -c opt //source/exe:envoy-static --sandbox_debug --verbose_failures --copt "-w" --copt "-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1" --cxxopt=-Wimplicit-fallthrough=0 --cxxopt=-Wno-error=type-limits

# Test command used to verify luajit/moonjit
# bazel test //test/extensions/filters/common/lua:lua_test -k --copt "-Wno-error=type-limits" --//source/extensions/filters/common/lua:moonjit=1
# bazel test //test/extensions/filters/http/lua:lua_filter_test -k --copt "-Wno-error=type-limits" --//source/extensions/filters/common/lua:moonjit=0
# bazel test //test/extensions/filters/common/lua:lua_test
# bazel test //test/extensions/filters/http/lua:lua_filter_test
