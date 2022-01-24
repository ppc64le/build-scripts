#----------------------------------------------------------------------------
#
# Package         : antlr4-runtime
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

REPO=https://github.com/antlr/antlr4.git

# Default tag antlr4-runtime
if [ -z "$1" ]; then
  export VERSION="4.2"
else
  export VERSION="$1"
fi


yum install -y git wget

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el8_4.ppc64le


wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.3-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.3-bin.tar.gz
mv /usr/local/apache-maven-3.8.3 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin


#Cloning Repo
git clone $REPO
cd antlr4
git checkout ${VERSION}
cd runtime/Java

#Build repo
mvn install
#Test repo
mvn test
 


         