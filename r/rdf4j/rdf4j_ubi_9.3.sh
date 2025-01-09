#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : rdf4j
# Version       : 5.1.0
# Source repo   : https://github.com/eclipse-rdf4j/rdf4j.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

# variables
PACKAGE_NAME=rdf4j
PACKAGE_URL=https://github.com/eclipse-rdf4j/rdf4j.git
PACKAGE_VERSION=${1:-5.1.0}

# install tools and dependent packages
#yum -y update
yum install -y git wget 
yum install -y gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

# setup java environment
#export JAVA_TOOL_OPTIONS="-Xms2048M -Xmx4096M -XX:MaxPermSize=4096M"
# update the path env. variable
yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="$JAVA_HOME/bin/":$PATH
java -version


# install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz
tar -xvzf apache-maven-3.9.8-bin.tar.gz
cp -R apache-maven-3.9.8 /usr/local
ln -s /usr/local/apache-maven-3.9.8/bin/mvn /usr/bin/mvn
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin





# clone, build and test specified version
#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
# Apply patches
wget https://raw.githubusercontent.com/sid226/build-scripts/refs/heads/sid226_rd/r/rdf4j/patch/patch_5.x.diff
git apply patch_5.x.diff


#Build
if !  mvn -B -U -T 2 clean install -Pquick,-formatting  ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

# Tests failures in parity with x86 rdf4j-shacl,-:rdf4j-sail-elasticsearch-store,-:rdf4j-sparql-compliance,-:rdf4j-elasticsearch-compliance,-:rdf4j-repository-compliance 
if ! mvn -B verify -P-skipSlowTests,-formatting -Dmaven.javadoc.skip=true -Djapicmp.skip -Denforcer.skip=true -Danimal.sniffer.skip=true -pl -:rdf4j-shacl,-:rdf4j-sail-elasticsearch-store,-:rdf4j-sparql-compliance,-:rdf4j-elasticsearch-compliance,-:rdf4j-repository-compliance  ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
