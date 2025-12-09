#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : waffle
# Version          : waffle-3.5.0
# Source repo      : https://github.com/Waffle/waffle.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=waffle
PACKAGE_URL=https://github.com/Waffle/waffle.git
PACKAGE_VERSION=${1:-waffle-3.5.0}

#dependencies
yum install -y git wget java-21-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-21)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java -version

# maven installation
wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar -xvzf apache-maven-3.9.9-bin.tar.gz
cp -R apache-maven-3.9.9 /usr/local
ln -s /usr/local/apache-maven-3.9.9/bin/mvn /usr/bin/mvn
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin
mvn -version


#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! mvn clean install -DskipTests; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
#skipping 3 tests as those are specific to windows
if ! mvn test -Dtest="\!WindowsLoginModuleTest,\!NegotiateSecurityFilterTest,\!WaffleInfoTest" -Dsurefire.failIfNoSpecifiedTests=false; then
    echo "------------------$PACKAGE_NAME:Build_success_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_Success_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
