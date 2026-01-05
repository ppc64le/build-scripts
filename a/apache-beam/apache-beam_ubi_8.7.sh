#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : beam
# Version          : v2.51.0
# Source repo      : https://github.com/apache/beam
# Tested on        : UBI 8.7
# Language         : Java,Go,Typescript,Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v2.51.0}
PACKAGE_NAME=beam
PACKAGE_URL=https://github.com/apache/beam

yum install -y git wget gcc gcc-c++ python3.11-pip python3.11 python3.11-devel java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless protobuf-c cmake gcc-gfortran openssl-devel openssl  python3-protobuf

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Install go
GO_VERSION=${GO_VERSION:-1.20.6}
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
go version

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxf apache-maven-3.8.1-bin.tar.gz
cp -R apache-maven-3.8.1 /usr/local
ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn
mvn --version

#install nodejs
NODE_VERSION=v18.9.0
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#Install Rust compiler
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

#install openblas
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
make -j8
make PREFIX=/usr/local/OpenBLAS install
export PKG_CONFIG_PATH=/usr/local/OpenBLAS/lib/pkgconfig
cd ..


# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test for Go module.
cd sdks/go
if ! go build ./... ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi
cd ..
if ! go test -coverprofile=coverage.txt -covermode=atomic ./go/pkg/... ./go/container/... ./java/container/... ./python/container/... ./typescript/container/. ; then
       echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
       exit 2
fi
cd ..

#Build and test for Java module
if ! ./gradlew -p sdks/java/ ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Build_and_Test_fails"
fi

#Build and test for Typescript module
cd sdks/typescript
if ! npm install ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi
if ! npm test ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi


