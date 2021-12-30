#! /bin/bash

# -----------------------------------------------------------------------------
# Package	: request-promise-native
# Version	: 1.0.7
# url       : https://github.com/request/request-promise-native
# Tested on	: "Red Hat Enterprise Linux 8.5" (Docker)
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


WORK_DIR=`pwd`

PACKAGE_NAME=request-promise-native
PACKAGE_VERSION=v1.0.7                 
PACKAGE_URL=https://github.com/request/request-promise-native.git

# install dependencies
dnf install git wget unzip -y

# install nodejs
dnf module install nodejs:10 -y

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# to install 
npm install yarn -g
yarn --ignore-engines

# to execute tests
if ! npm run test-publish ; then   # to test-without coverage
	set +ex
	echo "------------------Build Success but test fails---------------------"
else
	set +ex
	echo "------------------Build and test success-------------------------"
fi

