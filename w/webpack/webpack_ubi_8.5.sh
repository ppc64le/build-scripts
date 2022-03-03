# -----------------------------------------------------------------------------
#
# Package       : webpack
# Version       : v4.46.0
# Source repo   : https://github.com/webpack/webpack.git
# Tested on		: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> / <smohite@us.ibm.com> 
#
# Disclaimer    : This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
 
PACKAGE_NAME=webpack
PACKAGE_VERSION="${1:-v4.46.0}"
PACKAGE_URL=https://github.com/webpack/webpack.git


yum -y install git 
dnf module -y install nodejs:12

# Clone repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# To Build
npm install

# To test
npm install yarn -g

if ! npm test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
