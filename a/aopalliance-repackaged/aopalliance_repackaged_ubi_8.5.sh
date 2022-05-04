#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : aopalliance-repackaged
# Version       : v2.6.1
# Source repo	: https://repo1.maven.org/maven2/org/glassfish/hk2/external/aopalliance-repackaged/2.6.1/aopalliance-repackaged-2.6.1-sources.jar
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas /Vedang Wartikar <Vedang.Wartikar@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=aopalliance-repackaged
PACKAGE_VERSION=${1:-v2.6.1}

yum update -y && yum install -y wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel

export HOME=/home/tester

wget https://downloads.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz && tar -xzf apache-maven-3.8.4-bin.tar.gz -C /usr/lib/
export M2_HOME=/usr/lib/apache-maven-3.8.4
export M2=/usr/lib/apache-maven-3.8.4/bin/
export MAVEN_OPTS="-Xms2G -Xmx4G"
export PATH=/usr/lib/apache-maven-3.8.4/bin/:$PATH

mkdir -p $HOME/output
cd $HOME

wget https://repo1.maven.org/maven2/org/glassfish/hk2/external/aopalliance-repackaged/2.6.1/aopalliance-repackaged-2.6.1-sources.jar
jar xf aopalliance-repackaged-2.6.1-sources.jar


if ! mvn install -B -V; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi