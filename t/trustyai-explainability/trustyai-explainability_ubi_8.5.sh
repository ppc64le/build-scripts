#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : TrustyAI Explainability
# Source repo   : https://github.com/trustyai-explainability/trustyai-explainability
# Version       : v0.2.0
# Tested on     : UBI:8.5
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Viren Dalgade <Viren.Dalgade@ibm.com>
#
# Disclaimer: This script has been tested with non-root user on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
echo "creating trustyAI(non root user) user and swithching to trustyAI "
USER_NAME=trustyAI
USERDIR=/home/trustyAI
useradd --create-home --home-dir $USERDIR --shell /bin/bash $USER_NAME
usermod -aG wheel $USER_NAME
yum install -y sudo
su $USER_NAME
cd $USERDIR
echo " Current directory: $PWD "

#Installation of dependancies like java and maven
echo "Installing java"
PACKAGE_NAME="trustyai-explainability"
PACKAGE_URL="https://github.com/trustyai-explainability/trustyai-explainability"
PACKAGE_TAG=${1:-v0.2.0}
PACKAGE_BRANCH=main
yum install -y git wget java-17-openjdk java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
java -version
echo "Java 11 is installed"

#Installation of maven
echo "Installing maven 3.8.5"
MAVEN_VERSION=${MAVEN_VERSION:-3.8.5}
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin
mvn -version
echo "MAVEN 3.8.5 is installed"

#cloning the git repo of trustyai-explainability
#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_TAG | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | GitHub  | Fail |"
    exit 1
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"
git config --global --add safe.directory $USERDIR/$PACKAGE_NAME
chown -R $USER_NAME:$USER_NAME $USERDIR
cd $PACKAGE_NAME

#checkout to latest tag
if ! git checkout $PACKAGE_TAG ; then
    echo "------------------$PACKAGE_TAG:invalid tag---------------------------------------"
    exit 1
else 
    echo "------------------$PACKAGE_TAG:valid tag---------------------------------------"
fi

#package installation and verification with maven tool
if ! ( mvn install ); then
        echo "------------------$PACKAGE_NAME:install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |  Install_Success"
fi

if ! ( mvn test ); then
        echo "------------------$PACKAGE_NAME:test_cases_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Test_cases_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:test_cases_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |  Test_cases_Success"
fi

if ! ( mvn verify ); then
        echo "------------------$PACKAGE_NAME:verification_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Verification_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:verification_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |  Verification_Success"
fi




