# ----------------------------------------------------------------------------
#
# Package        : narayana-spring-boot
# Version        : release-2.6.0
# Source repo    : https://github.com/snowdrop/narayana-spring-boot.git
# Tested on      : ubi:8.3
# Script License : Apache License, Version 2 or later
# Maintainer     : Anant Pednekar <Anant.Pednekar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#Update Repos
#yum -y update

#Install Utilities
yum install -y git

# install Java
yum install -y java java-devel
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*ppc64le)')
# Set JAVA_HOME variable 
export JAVA_HOME=/usr/lib/jvm/$whichJavaString
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*jre-1.8)(?=.*ppc64le)')
export JRE_HOME=/usr/lib/jvm/$whichJavaString
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

# install maven
yum install -y wget tar
MAVEN_VERSION=3.8.1
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
export M2_HOME=/usr/local/maven
# update the path env. variable 
export PATH=$PATH:$M2_HOME/bin

#Clone repo
tagName=release-2.6.0
git clone https://github.com/snowdrop/narayana-spring-boot.git
cd narayana-spring-boot
git checkout tags/$tagName

#Build the Package
mvn clean install
#Test the Package
mvn test 