# ----------------------------------------------------------------------------
#
# Package       : infinispan
# Version       : 10.1.0.Beta1
# Source repo   : https://github.com/infinispan/infinispan
# Tested on     : ppc64le_rhel7.6
# Script License: Apache License, Version 2 or later
# Maintainer's  : Rashmi Sakhalkar <srashmi@us.ibm.com>
#                 
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
BUILD_VERSION=10.1.0.Beta1
BUILD_NETTY_VERSION=netty-tcnative-parent-2.0.25.Final
echo "`date +'%d-%m-%Y %T'` - Starting netty-tcnative build. Dependencies will be cloned in $BUILD_HOME"

# ------- Install dependencies -------

yum -y update

yum -y install subscription-manager.ppc64le
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
subscription-manager repos --enable rhel-7-for-power-le-extras-rpms
yum -y install epel-release

yum -y install gcc-c++.ppc64le
yum -y install wget git

yum install -y openssl-devel.ppc64le
yum install -y cmake.ppc64le cmake3.ppc64le
yum -y group install "Development Tools"

#Install jdk11 
yum install -y java-11-openjdk java-11-openjdk-devel

yum -y install ninja-build-1.7.2-2.el7.ppc64le
yum -y install golang
yum -y install autoconf automake libtool make tar glibc-devel libaio-devel openssl-devel apr-devel lksctp-tools
yum -y install apr-devel apr-util-devel


export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.3.7-0.el7_6.ppc64le
#Install maven
cd /
wget http://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz

tar xzf apache-maven-3.6.3-bin.tar.gz
 
ln -s apache-maven-3.6.3 /maven

export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn --version

cd /

git clone https://github.com/ninja-build/ninja.git
cd ninja
./configure.py --bootstrap
PATH=$PATH:/ninja/

echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "- --------------------------------------------------------------------------------------"

cd $BUILD_HOME

git clone https://github.com/netty/netty-tcnative

cd netty-tcnative && git checkout $BUILD_NETTY_VERSION

if grep 'http://archive.apache.org' pom.xml
then
    sed -i 's/http:\/\/archive.apache.org/https:\/\/archive.apache.org/g' pom.xml
fi

if grep 'executable=\"cmake\"' boringssl-static/pom.xml
then
    sed -i 's/executable="cmake"/executable="cmake3"/g' boringssl-static/pom.xml
fi

if grep 'executable=\"cmake\"' libressl-static/pom.xml
then
    sed -i 's/executable="cmake"/executable="cmake3"/g' libressl-static/pom.xml
fi

sed -i 's/executable="cmake"/executable="cmake3"/g' boringssl-static/pom.xml
sed -i 's/executable="cmake"/executable="cmake3"/g' libressl-static/pom.xml

mvn clean install
echo "`date +'%d-%m-%Y %T'` - Build netty-tcnative successfully -----------------------------------"
echo "- --------------------------------------------------------------------------------------"

echo "`date +'%d-%m-%Y %T'` - Building Infinispan -----------------------------------"
echo "- --------------------------------------------------------------------------------------"
cd $BUILD_HOME


git clone https://github.com/infinispan/infinispan

cd infinispan && git checkout $BUILD_VERSION

git apply $BUILD_HOME/Infini_fixes.patch

mvn -s maven-settings.xml clean install -Dmaven.test.failure.ignore=true

echo "`date +'%d-%m-%Y %T'` - Infinispan Complete -----------------------------------"
echo "- --------------------------------------------------------------------------------------"