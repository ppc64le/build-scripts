# ----------------------------------------------------------------------------
#
# Package         : tomcat
# Branch          : master
# Source repo     : https://github.com/apache/tomcat.git
# Tested on       : docker container, UBI 8
# Script License  : Apache License, Version 2.0
# Maintainer      : Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------

cd ${HOME}

yum update -y
yum install -y java-1.8.0-openjdk-devel wget git curl
export JAVA_HOME=`which java | xargs readlink -f | xargs dirname | xargs dirname | xargs dirname`

## Installing Apache-Ant
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.9-bin.tar.gz
tar -xf apache-ant-1.10.9-bin.tar.gz
export ANT_HOME=${HOME}/apache-ant-1.10.9/
export PATH=${PATH}:${ANT_HOME}/bin

## Building Tomcat
git clone https://github.com/apache/tomcat.git
cd tomcat
yes | cp build.properties.default build.properties
echo >> build.properties
echo "skip.installer=true" >> build.properties

## Build tomcat server
ant release

## Test Tomcat
export CATALINA_HOME=${HOME}/tomcat/output/dist
export PATH=${HOME}/tomcat/output/dist/bin:${PATH}
catalina.sh run &
curl localhost:8080
catalina.sh stop
