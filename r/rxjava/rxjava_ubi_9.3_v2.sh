#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: rxjava
# Version	: v2.2.21
# Source repo	: https://github.com/ReactiveX/RxJava
# Tested on	: UBI 9.3
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="rxjava"
PACKAGE_VERSION=${1:-v2.2.21}
PACKAGE_URL="https://github.com/ReactiveX/RxJava.git"

yum install -y wget git zip
yum -y update && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        exit 1
fi

cd RxJava
git checkout $PACKAGE_VERSION

function try_gradle_with_jdk8(){
echo "Building package with jdk 1.8"
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/jre-1.8.0-openjdk-*')
export PATH="$JAVA_HOME/bin/":$PATH
chmod u+x ./gradlew

    if ! ./gradlew build -Dorg.gradle.jvmargs=-Xmx2g  --stacktrace; then
                echo "------------------$PACKAGE_NAME:install_&_test_both_fail---------------------"
                exit 1
        else
                echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                exit 0
        fi


}

try_gradle_with_jdk8
