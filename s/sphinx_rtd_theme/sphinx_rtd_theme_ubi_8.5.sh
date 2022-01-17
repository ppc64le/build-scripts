# -----------------------------------------------------------------------------
#
# Package       : sphinx_rtd_theme
# Version       : 0.5.1
# Source repo   : https://github.com/readthedocs/sphinx_rtd_theme
# Tested on		: UBI 8.5
# Language      : Python
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

#Variables
PACKAGE_NAME=sphinx_rtd_theme
PACKAGE_VERSION="${1:-0.5.1}"
PACKAGE_URL=https://github.com/readthedocs/sphinx_rtd_theme.git

#Install dependencies.
yum install -y git python2 python2-devel python3 python3-devel gcc-c++ make

# node-gyp not compatible with node12
dnf module install nodejs:10 -y
pip3 install pytest tox

#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/

git checkout $PACKAGE_VERSION

# To Install
python3 setup.py install

# To test
if ! tox -e py36-sphinx24; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
else
	echo "------	------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
fi