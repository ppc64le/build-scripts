#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : icu
# Version          : release-75-rc
# Source repo      : https://github.com/unicode-org/icu
# Tested on        : UBI:9.3
# Language         : C++,Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-release-75-rc}
PACKAGE_NAME=icu
PACKAGE_URL=https://github.com/unicode-org/icu

yum install -y git wget gcc gcc-c++  java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxf apache-maven-3.8.1-bin.tar.gz
cp -R apache-maven-3.8.1 /usr/local
ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test icu4j
cd icu4j

if ! mvn clean install ; then
        echo "------------------$PACKAGE_NAME:Install_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails_"
        exit 1
fi

if ! mvn test ; then
       echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install _and_Test_fails"
       exit 2
fi
cd ..

#Build and test icu4c
cd icu4c/source
mkdir /tmp/icu_cnfg;
./runConfigureICU Linux --prefix=/tmp/icu_cnfg;

if ! make -j -l4.5 install ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi
if ! make check ; then
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
