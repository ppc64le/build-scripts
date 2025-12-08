#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : milvus
# Version       : 2.3.3
# Source repo   : https://github.com/milvus-io/milvus
# Tested on     : UBI 9.3 (docker)
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

SCRIPT_PACKAGE_VERSION=v2.3.3
PACKAGE_NAME=milvus
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/milvus-io/${PACKAGE_NAME}
CMAKE_VERSION=3.28.1
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

create_ibm_toolchain_repo()
{
touch /etc/yum.repos.d/advance-toolchain.repo
cat <<EOT >> /etc/yum.repos.d/advance-toolchain.repo
[advance-toolchain]
name=Advance Toolchain IBM FTP
baseurl=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9
enabled=1
gpgcheck=1
gpgkey=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1
EOT
}

#Install IBM Advanced Toolchain repo
yum install -y wget
wget https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1
rpm --import gpg-pubkey-615d762f-62f504a1
create_ibm_toolchain_repo

#Install and setup RHEL deps
yum install -y --allowerasing make wget git sudo curl zip unzip tar pkg-config python3-devel perl-IPC-Cmd perl-Digest-SHA perl-FindBin perl-File-Compare openssl-devel scl-utils advance-toolchain-at16.0-runtime advance-toolchain-at16.0-devel advance-toolchain-at16.0-perf
export PATH=/opt/at16.0/bin:$PATH
rm -rf /opt/at16.0/bin/pip3 /opt/at16.0/bin/python3
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install -y which \
      libaio libuuid-devel ncurses-devel \
      ccache libtool m4 autoconf automake \
      ninja-build rust
pip3 install conan==1.61.0


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
sudo dockerd &
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
yum remove -y gcc gcc-c++
yum install -y libxcrypt-devel
gcc --version
pushd /usr/local/cmake
create_cmake_conanfile
conan export-pkg . cmake/${CMAKE_VERSION}@ -s os="Linux" -s arch="ppc64le"
conan profile update settings.compiler.libcxx=libstdc++11 default
popd
#sed -i 's#"12.3"#"12.3", "11.4.1"#g' $HOME/.conan/settings.yml
sed -i 's#"12.3"#"12.3", "12.3.1"#g' $HOME/.conan/settings.yml
go mod tidy
export VCPKG_FORCE_SYSTEM_BINARIES=1
ret=0
make -j$(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi
export MILVUS_BIN=$wdir/milvis/bin/milvus

#Start Milvus dev stack
docker compose -f ./deployments/docker/dev/docker-compose.yml up -d

#Test
sed -i "44d" ./internal/core/thirdparty/knowhere/CMakeLists.txt
make test-go -j$(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "Tests fail."
	exit 2
fi
make test-cpp -j$(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "Tests fail."
	exit 2
fi

# Conclude
set +ex
echo "Complete: Build and Test successful! Milvus binary available at [$MILVUS_BIN]"
echo "8 (7 Cpp + 1 Go) Azure related tests were disabled: https://github.com/milvus-io/milvus/pull/29021"



