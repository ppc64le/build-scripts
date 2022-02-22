#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : jsr166-mirror
# Version          : master
# Source repo      : https://github.com/codehaus/jsr166-mirror
# Tested on        : UBI 8.5
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=jsr166-mirror
PACKAGE_URL=https://github.com/codehaus/jsr166-mirror
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-master}

#Dependencies
#yum install -y java-11-openjdk-devel git wget unzip
yum install -y git wget unzip

HOME=$(pwd)

wget https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
tar xf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
rm -rf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
export JAVA_HOME=$HOME/jdk-9.0.4+11
export PATH=$JAVA_HOME/bin:$PATH
mkdir -pm 700 jdk/jdk9 
#Path of jdk-9 is hardcoded in build.xml so coping into same dir.
cp -R /root/jdk-9.0.4+11/*  /root/jdk/jdk9
  
cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
rm -rf apache-ant-1.10.12-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.12
export PATH=/opt/apache-ant-1.10.12/bin:$PATH
export ANT_OPTS=-Dfile.encoding=UTF8


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi
 
# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ant; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! ant test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

#Test is in parity with intel. See readMe file for more details.