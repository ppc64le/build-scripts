#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : milvus
# Version       : 2.3.3
# Source repo   : https://github.com/milvus-io/milvus
# Tested on     : Ubuntu 22.04 (docker)
# Language      : C++, Go
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

PACKAGE_NAME=milvus
SCRIPT_PACKAGE_VERSION=v2.3.3
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/milvus-io/${PACKAGE_NAME}
CMAKE_VERSION=3.27.7
GO_VERSION=1.21.4
SCRIPT_PATH=$(dirname $(realpath $0))
wdir=`pwd`

if [ "$1" = "--power10" ]; then
	PACKAGE_VERSION=${SCRIPT_PACKAGE_VERSION}
	APPLYMCPU=1
fi

if [ "$2" = "--power10" ]; then
        APPLYMCPU=1
fi

create_cmake_conanfile()
{
touch /usr/local/cmake/conanfile.py
cat <<EOT >> /usr/local/cmake/conanfile.py
from conans import ConanFile, tools
class CmakeConan(ConanFile):
  name = "cmake"
  package_type = "application"
  version = "${CMAKE_VERSION}"
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

#Install IBM Advanced Toolchain repo
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y wget
wget -qO- https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/ubuntu/dists/jammy/615d762f.gpg.key | tee -a /etc/apt/trusted.gpg.d/615d762f.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/615d762f.asc] https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/ubuntu jammy at16.0"  >> /etc/apt/sources.list

# Install and setup Ubuntu deps
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y make wget git sudo curl zip unzip tar pkg-config libssl-dev advance-toolchain-at16.0-runtime advance-toolchain-at16.0-devel advance-toolchain-at16.0-perf advance-toolchain-at16.0-mcore-libs
DEBIAN_FRONTEND=noninteractive apt-get install -y gfortran ccache zlib1g-dev \
      lcov libtool m4 autoconf automake python3 python3-pip \
      pkg-config uuid-dev libaio-dev libgoogle-perftools-dev ninja-build rustc
pip3 install conan==1.61.0
export PATH=/opt/at16.0/bin:$PATH
rm -rf /opt/at16.0/bin/pip3 /opt/at16.0/bin/python3

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
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH
go version
export PATH=$PATH:$HOME/go/bin

#Install Docker
DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
service docker start
sleep 10
docker run hello-world

#Get milvus source and apply patch
cd $wdir
git clone -b ${PACKAGE_VERSION} ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}-${SCRIPT_PACKAGE_VERSION}.patch
if [ "$APPLYMCPU" -eq 1 ]; then
	sed -i "49d" ./internal/core/CMakeLists.txt
	sed -i '49i set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -mcpu=power10")' ./internal/core/CMakeLists.txt
fi

#Build
apt remove gcc g++ -y
pushd /usr/local/cmake
create_cmake_conanfile
conan export-pkg . cmake/${CMAKE_VERSION}@ -s os="Linux" -s arch="ppc64le"
conan profile update settings.compiler.libcxx=libstdc++11 default
popd
sed -i 's#"12.3"#"12.3", "12.3.1"#g' $HOME/.conan/settings.yml
go mod tidy
export VCPKG_FORCE_SYSTEM_BINARIES=1
make -j$(nproc)
export MILVUS_BIN=$wdir/milvis/bin/milvus

#Start Milvus dev stack
docker compose -f ./deployments/docker/dev/docker-compose.yml up -d

#Test
sed -i "44d" ./internal/core/thirdparty/knowhere/CMakeLists.txt
make test-go -j$(nproc)
make test-cpp -j$(nproc)

# Conclude
set +ex
echo "Complete: Build and Test successful! Milvus binary available at [$MILVUS_BIN]"
echo "8 (7 Cpp + 1 Go) Azure related tests were disabled: https://github.com/milvus-io/milvus/pull/29021"



