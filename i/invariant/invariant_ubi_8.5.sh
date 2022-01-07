# -----------------------------------------------------------------------------
# Package		: invariant
# Version		: 2.2.4
# url       	: https://github.com/zertosh/invariant
# Tested on		: "Red Hat Enterprise Linux 8.5" (Docker)
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

WORK_DIR=`pwd`

PACKAGE_NAME=invariant
PACKAGE_VERSION=v2.2.4                 
PACKAGE_URL=https://github.com/zertosh/invariant.git


dnf install git wget -y

# install nodejs
dnf module install nodejs:12 -y

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# To build 
npm install 

# To test
# 1 failing test is in parity with x86.

if ! npm test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
