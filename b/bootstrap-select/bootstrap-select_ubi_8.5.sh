# -----------------------------------------------------------------------------
#
# Package       : bootstrap-select
# Version       : v1.12.4
# Source repo   : https://github.com/snapappointments/bootstrap-select
# Tested on	    : UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> / <smohite@us.ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=bootstrap-select
PACKAGE_VERSION="${1:-v1.12.4}"
PACKAGE_URL=https://github.com/snapappointments/bootstrap-select.git

# Install Dependencies
yum -y install git wget gcc-c++ make python3

dnf module install -y nodejs:12

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone repo
git clone $PACKAGE_URL

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# To  build
if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" 
    exit 1
fi
npm audit fix

# To test
# No tests Specified
if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
    exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
fi
