#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : beam
# Version          : v2.56.0
# Source repo      : https://github.com/apache/beam
# Tested on        : UBI:9.3
# Language         : Java,Go,Typescript,Python
# Travis-Check     : True
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

PACKAGE_VERSION=${1:-v2.56.0}
PACKAGE_NAME=beam
PACKAGE_URL=https://github.com/apache/beam

yum install -y git wget gcc gcc-c++ python3.11-pip python3.11 python3.11-devel java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless protobuf-c cmake gcc-gfortran openssl-devel openssl  python3-protobuf

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Install go
wget https://go.dev/dl/go1.21.6.linux-ppc64le.tar.gz
tar -C /usr/local -xf go1.21.6.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

#install nodejs
export NODE_VERSION=${NODE_VERSION:-20}
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

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
if ! go test -coverprofile=coverage.txt -covermode=atomic ./go/pkg/... ./go/container/... ./java/container/... ./python/container/... ./typescript/container/.  --race; then
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


