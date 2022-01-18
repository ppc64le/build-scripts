# -----------------------------------------------------------------------------
#
# Package       : pyenchant
# Version       : v3.2.0
# Source repo   : https://github.com/pyenchant/pyenchant
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> / <smohite@us.ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

#Variables
PACKAGE_NAME=pyenchant
PACKAGE_VERSION="${1:-v3.2.0}"
PACKAGE_URL=https://github.com/pyenchant/pyenchant.git

#Install dependencies.
yum -y install git python36 python36-devel enchant

pip3 install pytest tox

#Clonning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! tox -e py36; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
else
	echo "------	------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
fi
