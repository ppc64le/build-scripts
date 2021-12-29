#----------------------------------------------------------------------------
#
# Package         : antlr4-annotations
# Version         : 4.2
# Source repo     : https://github.com/antlr/antlr4.git
# Tested on       : ubi:8.3
# Script License  : BSD license
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

set -e

REPO=https://github.com/antlr/antlr4.git

# Default tag antlr4-annotations
if [ -z "$1" ]; then
  export VERSION="4.2"
else
  export VERSION="$1"
fi

yum update -y
yum install -y git wget
yum install -y java-11-openjdk-devel

wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

#Cloning Repo
git clone $REPO
cd antlr4
git checkout ${VERSION}
cd runtime/JavaAnnotations

#Build repo
mvn install
#Test repo
mvn test
 


         