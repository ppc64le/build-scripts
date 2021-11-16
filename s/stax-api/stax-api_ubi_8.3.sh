#----------------------------------------------------------------------------
#
# Package         : Stax-api
# Version         : aalto-xml-1.0.0 
# Source repo     : https://github.com/FasterXML/aalto-xml.git
# Tested on       : ubi:8.3
# Script License  : Public Domain
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
#
# ----------------------------------------------------------------------------

REPO=https://github.com/FasterXML/aalto-xml.git

# Default tag stax-api
if [ -z "$1" ]; then
  export VERSION="aalto-xml-1.0.0"
else
  export VERSION="$1"
fi

yum install git wget -y

#install java8
yum install java-1.8.0-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-1.el8_4.ppc64le

#install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.3-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.3-bin.tar.gz
mv /usr/local/apache-maven-3.8.3 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin
#Cloning Repo
git clone $REPO
cd  aalto-xml/
git checkout ${VERSION}

#Build repo
mvn install
#Test repo
mvn test
 


         