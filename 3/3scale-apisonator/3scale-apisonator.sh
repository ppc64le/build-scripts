# -----------------------------------------------------------------------------
#
# Package	: 3scale-apisonator
# Version	: 2.14-stable
# Source repo	: https://github.com/3scale/apisonator.git
# Tested on	: Red Hat Enterprise Linux 87(8.7) && 9 (9.3)
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shubham Bhagwat(shubham.bhagwat@ibm.com)
#
# Disclaimer: This script has been tested in **root/non-root** mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# run as root user
# ----------------------------------------------------------------------------

#!/bin/bash

PACKAGE_NAME=apisonator
PACKAGE_VERSION=${1:-3scale-2.14-stable}
PACKAGE_URL=https://github.com/3scale/apisonator.git

yum install -y git make

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME   | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_VERSION ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 1
fi

echo "BRANCH_NAME = $PACKAGE_VERSION"

cd $PACKAGE_NAME

# build
if ! make ci-build ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi


#tests - run if needed 
#if ! make test; then
#		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
#		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
#		exit 1
#	else
#		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
#		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
#		exit 1
#fi
