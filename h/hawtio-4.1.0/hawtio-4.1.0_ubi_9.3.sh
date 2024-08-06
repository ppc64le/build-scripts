#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package        : hawtio
# Version        : 4.1.0
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

PACKAGE_NAME=hawtio
PACKAGE_URL=https://github.com/hawtio/hawtio
PACKAGE_VERSION=${1:-hawtio-4.1.0}

yum install git wget -y
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
yum install java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs 20.9.0"
nvm install 20.9.0  >/dev/null
nvm use 20.9.0
npm install -g npm@10.8.1
npm install --global yarn -y

wget https://archive.apache.org/dist/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.2-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.2-bin.tar.gz
mv /usr/local/apache-maven-3.8.2 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin



if ! mvn install -DskipTests; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL   $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
    exit 2;
fi

if ! mvn test -DskipTests; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 1;
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL    $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
    exit 0;
fi
