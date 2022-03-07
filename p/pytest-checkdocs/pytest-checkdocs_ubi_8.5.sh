#!binbash -e
# ----------------------------------------------------------------------------
#
# Package        pytest-checkdocs
# Version        v2.6.0
# Source repo    httpsgithub.comjaracopytest-checkdocs
# Tested on      UBI 8.5
# Language       Python
# Travis-Check   True
# Script License Apache License, Version 2 or later
# Maintainer     Valen Mascarenhas  Vedang Wartikar Vedang.Wartikar@ibm.com
#
# Disclaimer This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package andor distribution. In such case, please
#             contact Maintainer of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pytest-checkdocs
PACKAGE_VERSION={1-v2.6.0}
PACKAGE_URL=httpsgithub.comjaracopytest-checkdocs

yum -y update && yum install -y  git python36 make python3-devel gcc gcc-c++

mkdir -p hometesteroutput
cd hometester

# Download the repos
git clone $PACKAGE_URL

# Build and Test pytest-checkdocs
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install tox

if ! tox ; then
	echo ------------------$PACKAGE_NAMEbuild_test_failure---------------------
	exit 1
else
	echo ------------------$PACKAGE_NAMEbuild_test_success-------------------------
	exit 0
fi