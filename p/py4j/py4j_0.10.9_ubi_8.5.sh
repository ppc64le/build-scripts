#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package          : py4j
# Version          : 0.10.9
# Source repo      : https://github.com/py4j/py4j
# Tested on        : UBI 8.5
# Language         : Java,python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=py4j
PACKAGE_VERSION=${1:-0.10.9}
PACKAGE_URL=https://github.com/py4j/py4j

yum update -y
yum install -y git wget gcc java-1.8.0-openjdk-devel python38 python38-pip python38-devel python27

pip3 install pytest tox

wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd py4j-java
mvn install
mvn test

cd ..
cd py4j-python/
pip3 install -r requirements-test.txt

#Tests taking lot of time for execution. Please uncomment if needed.
#pytest
cd ../..
