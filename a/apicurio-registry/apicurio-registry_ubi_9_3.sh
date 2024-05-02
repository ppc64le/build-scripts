
#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : apicurio-registry
# Version       : 2.5.10.Final
# Source repo   : https://github.com/Apicurio/apicurio-registry
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=apicurio-registry
PACKAGE_VERSION=${1:-2.5.10.Final}
PACKAGE_URL=https://github.com/Apicurio/apicurio-registry

yum install -y git java-11-openjdk-devel wget
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin


#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"
fi

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/apicurio-registry/apicurio-registry_${PACKAGE_VERSION}.patch
git apply apicurio-registry_${PACKAGE_VERSION}.patch


if ! ./mvnw -Dmaven.test.failure.ignore=true install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! mvn test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
