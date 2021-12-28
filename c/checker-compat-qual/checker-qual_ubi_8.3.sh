#----------------------------------------------------------------------------
#
# Package         : typetools/checker-framework
# Version         : checker-framework-2.11.1
# Source repo     : https://github.com/typetools/checker-framework.git
# Tested on       : ubi:8.3
# Script License  : GNU General Public License, version 2 (GPL2)
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#Tested versions:checker-framework-2.11.1, checker-framework-2.5.2
# ----------------------------------------------------------------------------

REPO=https://github.com/typetools/checker-framework.git

# Default tag checker-framework
if [ -z "$1" ]; then
  export VERSION="checker-framework-2.11.1"
else
  export VERSION="$1"
fi

yum install git unzip wget -y

#install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.3-bin.tar.gz

#install gradle
wget https://downloads.gradle-dn.com/distributions/gradle-5.4-all.zip && mkdir /opt/gradle
unzip -d /opt/gradle gradle-5.4-all.zip
ls /opt/gradle/gradle-5.4/ && export PATH=$PATH:/opt/gradle/gradle-5.4/bin

#install java8
yum install java-1.8.0-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-1.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

#Cloning Repo
git clone $REPO
cd  checker-framework/
git checkout ${VERSION}
cd checker-qual

#Build Repo
gradle build 

#Test Repo
gradle test


         