#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: apache-freemarker
# Version	: v2.3.32
# Source repo	: https://github.com/apache/freemarker
# Tested on	: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=apache-freemarker
PACKAGE_VERSION=${1:-v2.3.32}
PACKAGE_URL=https://github.com/apache/freemarker

yum -y update
yum -y install java-1.8.0-openjdk-devel wget git 

wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.13-bin.tar.gz
tar xvfvz apache-ant-1.10.13-bin.tar.gz -C /opt
ln -s /opt/apache-ant-1.10.13 /opt/ant
sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment'
ln -s /opt/ant/bin/ant /usr/bin/ant

wget https://dlcdn.apache.org//ant/ivy/2.5.1/apache-ivy-2.5.1-bin.tar.gz
tar xvfvz apache-ivy-2.5.1-bin.tar.gz -C /opt/ant/lib

wget https://dlcdn.apache.org//commons/lang/binaries/commons-lang3-3.12.0-bin.tar.gz
tar xvfvz commons-lang3-3.12.0-bin.tar.gz  -C /opt/ant/lib

git clone $PACKAGE_URL
cd freemarker/
git checkout $PACKAGE_VERSION

ant download-ivy

if ! ant; then 
	echo "Build fails"
	exit 1
fi


echo "1i boot.classpath.j2se1.8=/usr/lib/jvm/jre/lib/rt.jar" > build.properties

if ! ant test; then
	echo "Test fails"
	exit 2
else
	echo "Build and test successful"
	exit 0
fi
   
