#!/bin/bash 
# ----------------------------------------------------------------------------
#
# Package        : hawtio
# Version        : 4.x
# Source repo    : https://github.com/hawtio/hawtio.git
# Tested on      : UBI:9.6
# Language       : Java
# Ci-Check   : True
# Script License : Apache License Version 2
# Maintainer     : Prasanna Marathe <prasanna.marathe@ibm.com>

# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
# Tests are failing on x86 for hawtio-4.4.1 and hawtio-4.40.0
PACKAGE_NAME=hawtio
PACKAGE_URL=https://github.com/hawtio/hawtio
PACKAGE_VERSION=4.x
MAVEN_VERSION=3.9.11

yum install git wget jq -y
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
#install JAVA17
yum install java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs 20.5.0"
nvm install 20.5.0  >/dev/null
nvm use 20.5.0
npm install -g npm@10.8.1
npm install --global yarn -y

wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz && tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz -C /usr/lib/
export M2_HOME=/usr/lib/apache-maven-$MAVEN_VERSION
export PATH=$PATH:$M2_HOME/bin

#Workaround: set swc core version to version  1.7.9 as higher swc versions does not support ppc64le 
export version="1.7.9"
cd console
cp package.json tmp_package.json
jq --arg version "$version" '.devDependencies."@swc/core" |= $version' tmp_package.json  > package.json
cd ..
echo $PWD

cd console-minimal
cp package.json tmp_package.json
jq --arg version "$version" '.devDependencies."@swc/core" |= $version' tmp_package.json  > package.json
cd ..
echo $PWD

cd examples/sample-plugin
cp package.json tmp_package.json
jq --arg version "$version" '.devDependencies."@swc/core" |= $version' tmp_package.json  > package.json
cd ../..
echo $PWD


if ! mvn --batch-mode --no-transfer-progress install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL   $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
    exit 2;
else
    echo "------------------$PACKAGE_NAME:Install_&_unit_test_both_success-------------------------"
    echo "$PACKAGE_URL    $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Build_and_springboot_and_quarkus_Test_Success"
    exit 0;
fi

