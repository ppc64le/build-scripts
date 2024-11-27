#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : pact-go
# Version               : v2.0.8
# Source repo           : https://github.com/pact-foundation/pact-go
# Tested on             : UBI:9.3
# Language              : Go
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v2.0.8}
PACKAGE_NAME=pact-go
PACKAGE_URL=https://github.com/pact-foundation/pact-go

yum install -y git gcc wget

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config info json-c python3-devel python3-pytest python3-sphinx gzip tar bzip2 zip unzip zlib-devel protobuf protobuf-devel protobuf-c protobuf-c-devel  java-11-openjdk-devel  libffi-devel clang clang-devel llvm-devel llvm-static clang-libs readline ncurses-devel pcre-devel pcre2-devel libcap rpm-build systemd-devel groff-base platform-python-devel readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison flex c-ares-devel  libcap-devel  


wget https://go.dev/dl/go1.21.6.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.21.6.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#Install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env

git clone https://github.com/pact-foundation/pact-reference.git
cd pact-reference/rust/pact_ffi

cargo build --release
cd ../..
cd rust/target/release/
cp libpact_ffi.so /usr/local/lib/
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export CGO_LDFLAGS="-L/usr/local/lib -lpact_ffi"
cd /

git clone https://github.com/pact-foundation/pact-plugins
cd pact-plugins
cd plugins/csv/
cargo build --release
cp /pact-plugins/plugins/csv/target/release/pact-csv-plugin /usr/local/lib/
cd /

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
go mod tidy

if ! go build ./... ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! go test ./... -race -coverprofile=profile.out -covermode=atomic ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi