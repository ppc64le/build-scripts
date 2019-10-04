# ----------------------------------------------------------------------------
#
# Package       : hawtjni
# Version       : 1.17-SNAPSHOT
# Source repo   : https://github.com/fusesource/hawtjni
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

echo "`date +'%d-%m-%Y %T'` - Staring hawtjni build. Dependencies will be cloned in $BUILD_HOME"

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

yum -y install ninja-build-1.7.2-2.el7.ppc64le
yum -y install golang
yum -y install autoconf automake libtool make tar glibc-devel libaio-devel openssl-devel apr-devel lksctp-tools

cd /opt
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar xzf apache-maven-3.6.2-bin.tar.gz
ln -s apache-maven-3.6.2 maven
export M2_HOME=/opt/maven
echo "
export PATH=${M2_HOME}/bin:${PATH}
" > /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

cd $BUILD_HOME

echo "`date +'%d-%m-%Y %T'` - Installed Standerd Packages -----------------------------------"
echo "---------------------------------------------------------------------------------------"

# ------- Clone and build the missing dependencies -------



# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.ppc64le/

if [[ $# -ne 0 ]] ; then
    echo "branch = $1"
    git clone -b $1 https://github.com/fusesource/hawtjni
else
    echo "cloning master"
    git clone https://github.com/fusesource/hawtjni
fi

cd hawtjni
mvn install

cd $BUILD_HOME

echo "`date +'%d-%m-%Y %T'` - Installed hawtjni ----------------------------------------------"
echo "- --------------------------------------------------------------------------------------"


