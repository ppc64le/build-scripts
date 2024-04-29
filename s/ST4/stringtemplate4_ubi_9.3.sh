#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : stringtemplate4
# Version       : 4.3.3
# Source repo   : https://github.com/antlr/stringtemplate4.git
# Tested on     : UBI: 9.3
# Language      : Java
# Travis-Check  : True
# Script License: The BSD License
# Maintainer's  : Vinod K <Vinod.K1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=stringtemplate4
PACKAGE_VERSION=${1:-4.3.3}
PACKAGE_URL=https://github.com/antlr/stringtemplate4.git

# install dependencies
yum install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
    https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum install -y git java-11-openjdk-devel xorg-x11-server-Xvfb

# install maven
curl -s -L https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz | tar xvz
export M2_HOME=/apache-maven-3.9.6
export PATH=$M2_HOME/bin:$PATH

# clone package
mkdir $PACKAGE_NAME
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# to build
mvn install -DskipTests=true

# setup x11 for tests
export DISPLAY=:1
Xvfb $DISPLAY -screen 0 1024x768x16 &

# to execute tests
mvn test

