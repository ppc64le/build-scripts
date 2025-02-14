#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : mariadb-connector-j
# Version       : 3.4.1
# Source repo   : https://github.com/mariadb-corporation/mariadb-connector-j
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
PACKAGE_NAME=mariadb-connector-j
PACKAGE_URL=https://github.com/mariadb-corporation/mariadb-connector-j
PACKAGE_VERSION=${1:-3.4.1}

# install tools and dependent packages
#yum -y update
yum install -y git wget 
yum install -y gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

# setup java environment
export JAVA_TOOL_OPTIONS="-Xms2048M -Xmx4096M -XX:MaxPermSize=4096M"
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

#Build
if ! mvn -Dmaven.test.skip -Dmaven.javadoc.skip package ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

# Tests require setting up mariadb container
# Testcase failures are in parity with intel
# docker run --detach --network=host --name mariadb-container --env MARIADB_USER=example-user --env MARIADB_PASSWORD=my_cool_secret --env MARIADB_DATABASE=testj --env MARIADB_ROOT_PASSWORD=my-secret-pw  ppc64le/mariadb:latest
# root@d765097f9cc7:/# mariadb -u root -p
#Enter password: my-secret-pw
#
#Setup root user with no password
#MariaDB [(none)]> ALTER USER 'root'@'localhost' IDENTIFIED BY '';
#ALTER USER 'root'@'%' IDENTIFIED BY '';
# if ! mvn test ; then
#     echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#     exit 0
# fi
#
