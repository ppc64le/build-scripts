#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : moment
# Version          : 2.30.1
# Source repo      : https://github.com/moment/moment.git
# Tested on        : UBI 8.4
# Language         : Javascript
# Travis-Check     : True
# Script License   : MIT Licence
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
#-------------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_NAME=moment
export PACKAGE_URL=https://github.com/moment/moment.git
export PACKAGE_VERSION=${1:-2.30.1}

#installing dependencies
yum install -y git


#installing nvm and npm

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install node
npm install -g npm

#clone the repository

git clone https://github.com/moment/moment.git
cd moment
git checkout $PACKAGE_VERSION

#Checking for various conditions
if ! npm install && npm audit fix $$ npm audit fix --force ;
then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1

elif ! npm test ;
then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
   	echo "$PACKAGE_URL $PACKAGE_NAME"
    	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    	exit 2	
else
	else
   	echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    	echo "$PACKAGE_URL $PACKAGE_NAME"
    	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    	exit 0
fi


