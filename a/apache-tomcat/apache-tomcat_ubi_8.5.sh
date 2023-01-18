#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: tomcat
# Version	: v11.0.0-M1
# Source repo	: https://github.com/apache/tomcat.git
# Tested on	: ubi 8.5
# Language      : go
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


PACKAGE_NAME=https://github.com/apache/tomcat.git
PACKAGE_VERSION=${1:-v11.0.0-M1}
PACKAGE_URL=https://github.com/apache/tomcat.git

cd ${HOME}
yum update -y
TOMCAT_VERSION="11.0.0"

yum install -y git wget
yum install -y java-11-openjdk-devel

## Installing Apache-Ant

wget http://mirror.downloadvn.com/apache/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
export ANT_HOME=${HOME}/apache-ant-1.10.12/
export PATH=${PATH}:${ANT_HOME}/bin

## Configuring Tomcat build

git clone https://github.com/apache/tomcat.git
cd tomcat
git checkout 11.0.0-M1
yes | cp build.properties.default build.properties
echo >> build.properties
echo "skip.installer=true" >> build.properties

## Building tomcat server

ant release

## Testing Tomcat

export CATALINA_HOME=${HOME}/tomcat/output/dist
export PATH=${HOME}/tomcat/output/dist/bin:${PATH}
catalina.sh start &
catalina.sh run &

sleep 30

curl localhost:8080

catalina.sh stop
