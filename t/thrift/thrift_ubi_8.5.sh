# -----------------------------------------------------------------------------
#
# Package	: thrift
# Version	: v0.13.0
# Source repo	: https://github.com/apache/thrift
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=thrift
PACKAGE_VERSION=${1:-v0.13.0}
PACKAGE_URL=https://github.com/apache/thrift

# Include CentOS Repos
dnf -y install \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm

yum -y groupinstall "Development Tools"
yum install -y boost libevent-devel zlib-devel openssl-devel python3 python3-devel

# Create symlink for python
ln -s /usr/bin/python3 /usr/bin/python

HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! ./bootstrap.sh; then
	echo "------------------$PACKAGE_NAME:bootstrap_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Bootstrap_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! ./configure; then
	echo "------------------$PACKAGE_NAME:configure_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Configure_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! make; then
	echo "------------------$PACKAGE_NAME:make_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Make_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! make install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! make -k check; then
	echo "------------------$PACKAGE_NAME:check_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Check_Fails"
	exit 1
fi

if ! make cross; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
