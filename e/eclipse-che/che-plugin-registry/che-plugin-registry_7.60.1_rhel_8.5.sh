# ----------------------------------------------------------------------------
#
# Package         : eclipse/che-plugin-registry
# Version         : 7.60.1
# Source repo     : https://github.com/eclipse/che-plugin-registry
# Tested on       : rhel_8.5
# Script License  : Apache License, Version 2.0
# Maintainer      : Shubham Bhagwat <shubham.bhagwat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WORKDIR=`pwd`
BUILD_VERSION=7.60.1
PACKAGE_URL=https://github.com/eclipse/che-plugin-registry.git 
PACKAGE_NAME=che-plugin-registry

echo "Installing libraries and dependencies..."

yum install git -y
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
yum install npm -y

echo "configuring npm and nvm..."

npm install -g -y yarn
nvm install 14
nvm use 14

echo "Installing additional dependencies..."

yum install -y python39
export PYTHONPATH=/usr/local/bin/python3

echo "cloning the repository..."

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
    rm -rf $PACKAGE_NAME
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_Fails"
    exit 0
fi

cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

sed -i 's/x86_64/ppc64le/g' build/dockerfiles/Dockerfile
sed -i 's/x64/ppc64le/g' build/dockerfiles/import-vsix.sh

echo "building..."
if ! ./build.sh -t 7.60.1-rhel; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    echo "------------------Second execution Re-run for flaky test case ---------------------"    

    if ! ./build.sh -t 7.60.1-rhel; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
    else    
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
    fi                
fi



