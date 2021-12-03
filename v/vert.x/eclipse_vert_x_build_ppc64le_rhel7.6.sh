# ----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 4.0.0-SNAPSHOT
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : ppc64le_rhel7.6
# Script License: Apache License, Version 2 or later
# Maintainer's  : Santosh Magdum <santosh.magdum@us.ibm.com>
#                 Priya Seth <priya.seth@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

BUILD_HOME=`pwd`

echo "`date +'%d-%m-%Y %T'` - Staring eclipse vert.x build. Dependencies will be cloned in $BUILD_HOME"

# ------- Install dependencies -------

yum -y update

yum -y install subscription-manager.ppc64le
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
subscription-manager repos --enable rhel-7-for-power-le-extras-rpms
yum -y install epel-release

yum -y install gcc-c++.ppc64le
yum -y install wget
yum -y install git
yum -y install java-1.8.0-openjdk-devel
yum install -y openssl-devel.ppc64le
yum -y group install "Development Tools"

yum -y install ninja-build.ppc64le
yum -y install golang
yum -y install autoconf automake libtool make tar glibc-devel libaio-devel openssl-devel apr-devel lksctp-tools
yum -y install apr-devel apr-util-devel

echo "`date +'%d-%m-%Y %T'` - Installed Standard Packages -----------------------------------"
echo "---------------------------------------------------------------------------------------"


# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/jre

cd $BUILD_HOME

if [[ $# -ne 0 ]] ; then
    git clone -b $1 https://github.com/eclipse-vertx/vert.x
else
    git clone https://github.com/eclipse-vertx/vert.x
fi

cd vert.x

mvn clean install

cd $BUILD_HOME

echo "`date +'%d-%m-%Y %T'` - Installed eclipse vert.x ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"
