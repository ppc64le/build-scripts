#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : JSON
# Version          : 4.10
# Source repo      : https://github.com/makamaka/JSON.git
# Tested on        : UBI 8.4
# Language         : Perl,Raku
# Travis-Check     : True
# Script License   : -----------
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

#Variables
PACKAGE_NAME=JSON
PACKAGE_VERSION=${1:-4.10}
PACKAGE_URL=https://github.com/makamaka/JSON.git

#installing dependencies
yum install -y git perl make


#clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#Build and run test cases
perl Makefile.PL
make test




