#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zookeeper
# Version       : release-3.7.0
# Source repo   : https://github.com/apache/zookeeper.git
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : kandarpa.malipeddi@ibm.com
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zookeeper
PACKAGE_VERSION=${1:-release-3.7.0}

#Begin Dependencies
yum install -y sudo
sudo yum install -y git wget maven hostname automake libtool autoconf-2.69 gcc-c++ make
sudo yum install -y http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/Packages/cppunit-1.14.0-4.el8.ppc64le.rpm http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/Packages/cppunit-devel-1.14.0-4.el8.ppc64le.rpm
export JAVA_HOME=/usr/lib/jvm/java-1.8.0/
#End Dependencies

#Begin Clone Code
echo "Cloning code..."
cd $HOME
git clone https://github.com/apache/zookeeper.git 
cd zookeeper
git checkout $PACKAGE_VERSION
#End Clone Code

#Begin Build
echo "Building product"
cd $HOME/zookeeper
mvn clean install -DskipTests
#End Build

#Begin Test
echo "Running Tests"
cd $HOME/zookeeper
mvn apache-rat:check verify -DskipTests spotbugs:check checkstyle:check -Pfull-build  -Dlicense.skip  -Dlicense.skipDownloadLicenses -Drat.numUnapprovedLicenses=100
#End Test