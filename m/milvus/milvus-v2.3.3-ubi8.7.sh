#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : milvus
# Version       : 2.3.3
# Source repo   : https://github.com/milvus-io/milvus
# Tested on     : UBI 8.7 (docker)
# Language      : C++, Go
# Travis-Check  : True
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

PACKAGE_NAME=milvus
PACKAGE_VERSION=${1:-v2.3.3}
PACKAGE_URL=https://github.com/milvus-io/${PACKAGE_NAME}
CMAKE_VERSION=3.27.7
wdir=`pwd`

create_cmake_conanfile()
{
touch /usr/local/cmake/conanfile.py 
cat <<EOT >> /usr/local/cmake/conanfile.py
from conans import ConanFile, tools

class CmakeConan(ConanFile):
  name = "cmake"
  package_type = "application"
  version = "3.27.7"
  description = "CMake, the cross-platform, open-source build system."
  homepage = "https://github.com/Kitware/CMake"
  license = "BSD-3-Clause"
  topics = ("build", "installer")
  settings = "os", "arch"
  def package(self):
    self.copy("*")
  def package_info(self):
    self.cpp_info.libs = tools.collect_libs(self)
EOT
}

#Install repos
dnf -y install \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo

#Install and setup RHEL deps
yum install -y make wget git sudo curl zip unzip tar pkg-config openssl-devel gcc-toolset-11-toolchain 

#Activate gcc 11 toolset
source scl_source enable gcc-toolset-11

#Install cmake
cd $wdir
if [ -z "$(ls -A $wdir/cmake-${CMAKE_VERSION})" ]; then
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

#Install Golang
cd $wdir
wget https://go.dev/dl/go1.20.5.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.5.linux-ppc64le.tar.gz
rm -rf go1.20.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
export PATH=$PATH:$HOME/go/bin

#Install Docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"mtu": 1450
}
EOT
systemctl start docker
docker run hello-world

#Get milvus source and apply patch
cd $wdir
git clone -b ${PACKAGE_VERSION} ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git apply ../milvus-${PACKAGE_VERSION}.patch

#Build
scripts/install_deps.sh
pushd /usr/local/cmake
create_cmake_conanfile
conan export-pkg . cmake/${CMAKE_VERSION}@ -s os="Linux" -s arch="ppc64le"
conan profile update settings.compiler.libcxx=libstdc++11 default
popd
go mod tidy
export VCPKG_FORCE_SYSTEM_BINARIES=1
make -j$(nproc)
export MILVUS_BIN=$wdir/milvis/bin/milvus

#Start Milvus dev stack
docker compose -f ./deployments/docker/dev/docker-compose.yml up -d

#Test
sed -i "43d" ./internal/core/thirdparty/knowhere/CMakeLists.txt
make test-go -j$(nproc)
make test-cpp -j$(nproc)

#Conclude
set +ex
echo "Complete: Build and Test successful! Milvus binary available at [$MILVUS_BIN]"
echo "8 (7 Cpp + 1 Go) Azure related tests were disabled: https://github.com/milvus-io/milvus/pull/29021"
