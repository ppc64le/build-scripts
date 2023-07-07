#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: architect
# Version	: v0.1.1
# Source repo	: https://github.com/pages-themes/architect
# Tested on	: ubi 8.5
# Language      : Ruby
# Travis-Check  : True
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

PACKAGE_NAME="jekyll-theme-architect"
PACKAGE_VERSION=${1:-"v0.1.1"}
PACKAGE_URL="https://github.com/pages-themes/architect"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "installing dependencies from system repo..."
dnf install -qy git make gcc-c++ redhat-rpm-config ruby-devel zlib-devel glibc-locale-source glibc-langpack-en

localedef -c -f UTF-8 -i en_US en_US.UTF-8
export LC_ALL=en_US.UTF-8
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
gem install bundler -v 2.3.10
bundle add html-proofer -v 3.9.1
bundle add rubocop -v 0.58.0
bundle add jekyll -v 3.8.2

if ! (bundle install || bundle update); then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

gem uninstall -i /usr/share/gems rubocop -v 0.93.1
rubocop -a

if ! ./script/cibuild; then
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
