#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: os-locale
# Version	: v3.1.0,v4.0.0
# Source repo	: https://github.com/sindresorhus/os-locale
# Tested on	: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saraswati Patra <Saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=os-locale
PACKAGE_VERSION=${1:-v3.1.0}
PACKAGE_URL=https://github.com/sindresorhus/os-locale

yum install -y yum-utils git jq

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install --save-dev mocha
if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! npm test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" 
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
#Build passed and Test is in parity with intel.

 #2 tests failed

 #sync

 # /root/os-locale/test.js:35

 # 34:   console.log('Locale identifier:', locale);
 #35:   t.true(locale.length > 1);
 #36:   t.true(locale.includes('-'));

 #Value is not `true`:

 #false



 # async

 # /root/os-locale/test.js:28

 #  27:   console.log('Locale identifier:', locale);
 # 28:   t.true(locale.length > 1);
 #  29:   t.true(locale.includes('-'));

 # Value is not `true`:

 # false

#npm ERR! Test failed.  See above for more details.
#------------------os-locale:install_success_but_test_fails---------------------
#https://github.com/sindresorhus/os-locale os-locale
#os-locale  |  https://github.com/sindresorhus/os-locale | v4.0.0 | "Red Hat Enterprise Linux 8.6 (Ootpa)" | GitHub | Fail |  Install_success_but_test_Fails
#[root@238c540f1039 ~]#
