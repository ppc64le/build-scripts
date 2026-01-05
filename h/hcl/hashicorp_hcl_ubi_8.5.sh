# -----------------------------------------------------------------------------
#
# Package	: github.com/hashicorp/hcl
# Version	: v1.0.0
# Source repo	: https://github.com/hashicorp/hcl
# Tested on	: UBI 8.5
# Language      : GO
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/hashicorp/hcl
PACKAGE_VERSION=${1:-v1.0.0}
PACKAGE_URL=https://github.com/hashicorp/hcl
PACKAGE_PATH=go/pkg/mod
USERNAME=tester

yum install -y git golang make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Create a non-root user as a test case will fail in root mode
useradd $USERNAME

# Clone into /home/$USERNAME/go/pkg/mod to install a golang package
runuser -l $USERNAME -c "mkdir -p /home/$USERNAME/go/pkg/mod"

if ! runuser -l $USERNAME -c "git clone $PACKAGE_URL $PACKAGE_PATH/$PACKAGE_NAME"; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# Checkout to Version & Use a fix from PR #273
runuser -l $USERNAME -c "cd /home/$USERNAME/$PACKAGE_PATH/$PACKAGE_NAME && git checkout $PACKAGE_VERSION && git pull origin pull/273/head"

if ! runuser -l $USERNAME -c "cd /home/$USERNAME/$PACKAGE_PATH/$PACKAGE_NAME && make"; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
	exit 0
fi
