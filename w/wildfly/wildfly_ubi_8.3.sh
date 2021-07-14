# ----------------------------------------------------------------------------
#
# Package        : Wildfly
# Version        : 24.0.0.Final
# Source repo    : https://github.com/wildfly/wildfly
# Tested on      : ubi:8.3
# Script License : GNU Lesser General Public License Version 2.1
# Maintainer     : Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#install git
dnf install git

#install JDK 8 or newer
dnf install java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.11.0.9-2.el8_4.ppc64le

#install Maven 3.6.0 or newer 
dnf -y install wget
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /opt/maven
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.11.0.9-2.el8_4.ppc64le
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

#Clone wildfly repo

if [ -z $1 ] || [ "$1" == "latestrelease" ]
then
	
	RELEASE_TAG=24.0.0.Final
else
	RELEASE_TAG=$1
fi

echo "RELEASE_TAG= $RELEASE_TAG"

(git clone -b $RELEASE_TAG https://github.com/wildfly/wildfly) || (echo "git clone failed"; exit $?)
cd wildfly


#Build and Test package
mvn install
