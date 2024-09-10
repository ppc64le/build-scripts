#!/bin/bash -e
# ---------------------------------------------------------------------
#
# Package       : event-driven-ansible
# Version       : v2.0.0
# Source repo   : https://github.com/ansible/event-driven-ansible/
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ashwini Kadam <Ashwini.Kadam@ibm.com>,Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------
PACKAGE_NAME=event-driven-ansible
PACKAGE_URL=https://github.com/ansible/event-driven-ansible/
PACKAGE_VERSION=${1:-v2.0.0}

yum install java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless openssl-devel sudo git wget tar python-devel python3-pip gcc gcc-c++ cmake.ppc64le systemd-devel zlib-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install rust
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
sudo ./install.sh
export PATH=$HOME/.cargo/bin:$PATH
cd ../

#Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn
    
mkdir -p ansible_collections/ansible
git clone $PACKAGE_URL
mv event-driven-ansible ansible_collections/ansible/eda
cd ansible_collections/ansible/eda
git checkout $PACKAGE_VERSION
sudo dnf remove -y python3-chardet
python3 -m pip install --upgrade pip setuptools wheel tox
python3 -m pip install -r requirements.txt


if ! python3 -m pip install -r test_requirements.txt ; then
     echo "------------------$PACKAGE_NAME:Build_fails---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
     exit 2
fi

if ! tox -e py39-unit ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 1
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
