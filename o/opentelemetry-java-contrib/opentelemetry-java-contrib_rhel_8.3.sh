#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-java-contrib
# Version	: v1.16.0                                                                                                                                                                                                          
# Source repo	: https://github.com/open-telemetry/opentelemetry-java-contrib
# Tested on	: rhel 8.3
# Language      : java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-java-contrib"
PACKAGE_VERSION=${1:-"v1.16.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-java-contrib"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "insstalling dependencies from system repo..."

dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf install -qy java-17-openjdk-devel

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"

cd "$HOME_DIR"/$PACKAGE_NAME
if ! ./gradlew build; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! ./gradlew test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
