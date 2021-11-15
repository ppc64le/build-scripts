#----------------------------------------------------------------------------
#
# Package         : apache/directory-ldap-api
# Version         : 2.1.0
# Source repo     : https://github.com/apache/directory-ldap-api.git
# Tested on       : ubi:8.3
# Script License  : Apache License 2.0
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
#
# ----------------------------------------------------------------------------

REPO=https://github.com/apache/directory-ldap-api.git

# Default tag directory-ldap-api
if [ -z "$1" ]; then
  export VERSION="2.1.0"
else
  export VERSION="$1"
fi

#install Java8
yum install java-1.8.0-openjdk-devel git wget -y
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le
export PATH=${JAVA_HOME}/bin:${PATH}

#install maven
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}


#Cloning Repo
git clone $REPO
cd directory-ldap-api
git checkout ${VERSION}


#Build repo
mvn install
#Test repo
mvn test
 


         