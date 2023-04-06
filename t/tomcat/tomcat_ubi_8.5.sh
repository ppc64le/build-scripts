#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: tomcat
# Version	: v11.0.0-M3
# Source repo	: https://github.com/apache/tomcat.git
# Tested on	: ubi 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=tomcat
PACKAGE_VERSION=${1:-11.0.0-M3}
PACKAGE_URL=https://github.com/apache/tomcat.git

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

cd ${HOME}
yum update -y
TOMCAT_VERSION="11.0.0"
yum install -y git wget
yum install -y java-17-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.6.0.10-3.el8_7.ppc64le
export PATH=$JAVA_HOME/bin:$PATH

## Installing apache-ant
wget http://mirror.downloadvn.com/apache/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
export ANT_HOME=${HOME}/apache-ant-1.10.12/
export PATH=${PATH}:${ANT_HOME}/bin

##Cloning the repo
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

##Configuring tomcat build
cd tomcat
git checkout $PACKAGE_VERSION
yes | cp build.properties.default build.properties
echo >> build.properties
echo "skip.installer=true" >> build.properties

##Building tomcat server

if ! ant release ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

export CATALINA_HOME=${HOME}/tomcat/output/dist
export PATH=${HOME}/tomcat/output/dist/bin:${PATH}

echo "==========================================================================="
echo "Tomcat server installed successfully. Use below commands to start the server"
echo "============================================================================"

##Testing tomcat server on port 8080

echo "export CATALINA_HOME=${HOME}/tomcat/output/dist"
printf 'export PATH=%s/tomcat/output/dist/bin:${PATH} \n' "${HOME}"
echo "cd ${HOME}/tomcat/output/dist/bin"
printf "\n"
echo "Start the server using command(server might take few seconds to start): catalina.sh run &"
echo "curl localhost:8080"
printf "\n"
echo "To stop the server: catalina.sh stop"
