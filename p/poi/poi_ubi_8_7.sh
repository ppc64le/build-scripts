#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : poi
# Version       : REL_5_2_3
# Source repo   : https://github.com/apache/poi
# Tested on     : UBI: 8.7
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
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
PACKAGE_NAME=poi
PACKAGE_URL=https://github.com/apache/poi
export PACKAGE_VERSION="REL_5_2_3"

 

# Default tag poi
if [ -z "$1" ]; then
  export PACKAGE_VERSION="REL_5_2_3"
else
  export PACKAGE_VERSION="$1"
fi

 

# install tools and dependent packages
sudo yum install -y wget git fontconfig-devel.ppc64le

 
#installing openjdk 11
sudo yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH


 

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
sudo tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
sudo mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

 


#installing ant 1.10.12
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -zxvf apache-ant-1.10.12-bin.tar.gz 
sudo mv apache-ant-1.10.12 /opt/ant
export ANT_HOME=/opt/ant
export PATH=$ANT_HOME/bin:$PATH
ant -version

 

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"
fi

 

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION

 

#Build and test package
if ! ./gradlew clean build -PjdkVersion=11 --no-daemon --refresh-dependencies -x test; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi
if ! ./gradlew test -PjdkVersion=11 --no-daemon --refresh-dependencies;then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_success_and_test_success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi
