#----------------------------------------------------------------------------
#
# Package         : apache/commons-fileupload
# Version         : commons-fileupload-1.4
# Source repo     : https://github.com/apache/commons-fileupload.git
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
#Tested versions:FILEUPLOAD_1_3, commons-fileupload-1.4
#
# ----------------------------------------------------------------------------

REPO=https://github.com/apache/commons-fileupload.git

# Default tag commons-fileupload
if [ -z "$1" ]; then
  export VERSION="commons-fileupload-1.4"
else
  export VERSION="$1"
fi

yum install -y java-1.8.0-openjdk-devel git wget
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-1.el8_4.ppc64le
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

#Cloning Repo
git clone $REPO
cd  commons-fileupload/
git checkout ${VERSION}

#Build repo
mvn install
#Test repo
mvn test
 


         