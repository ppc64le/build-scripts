#!/bin/bash 
# ----------------------------------------------------------------------------
#
# Package        : hawtio
# Version        : 4.x
# Source repo    : https://github.com/hawtio/hawtio.git
# Tested on      : UBI:9.3
# Language       : Java
# Travis-Check   : True
# Script License : Apache License Version 2
# Maintainer     : Radhika Ajabe <Radhika.Ajabe@ibm.com>

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

wget https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz && tar -xzf apache-maven-3.9.9-bin.tar.gz -C /usr/lib/
export M2_HOME=/usr/lib/apache-maven-3.9.9
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



if ! mvn install -DskipTests; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL   $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
    exit 2;
fi

if ! mvn install -Pe2e,e2e-springboot -am -pl :hawtio-test-suite -Dlocal-app=true; then
    echo "------------------$PACKAGE_NAME:Install_success_but_springboot test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 1;
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL    $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Build_and_springboot_Test_Success";
fi

if ! mvn install -Pe2e,e2e-quarkus -am -pl :hawtio-test-suite -Dlocal-app=true; then
    echo "------------------$PACKAGE_NAME:Install_success_but_quarkus test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_quarkus_test_Fails"
    exit 1;
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL    $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Build_and_springboot_and_quarkus_Test_Success"
    exit 0;
fi
