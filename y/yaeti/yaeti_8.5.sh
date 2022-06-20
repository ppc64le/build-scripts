#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: yaeti
# Version	: master
# Source repo	: https://github.com/ibc/yaeti.git
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

PACKAGE_NAME=yaeti
#PACKAGE_VERSION=${1:-master}
PACKAGE_VERSION=${1:-0.0.6}
PACKAGE_URL=https://github.com/ibc/yaeti.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm git jq

npm install n -g && n latest && npm install -g npm@latest
export npm_config_yes=true

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
# ----------------------------------------------------------------------------
# No test available, > yaeti@1.0.3 test /root/yaeti
#echo 'Error: no test specified'

#Error: no test specified
#"gulp": "git+https://github.com/gulpjs/gulp.git#4.0",
#sed -i '16d' /root/yaeti/package.json
sed -i '16d' /yaeti/package.json

if ! npm install && npm audit fix && npm audit fix --force; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_success &_test_not_available-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 0
	fi
#https://jazz06.rchland.ibm.com:12443/jazz/web/projects/Power%20Ecosystem#action=com.ibm.team.workitem.viewWorkItem&id=149836
#version:0.0.6
#Source Repo: https://github.com/ibc/yaeti.git
#License Link: https://github.com/ibc/yaeti/blob/master/LICENSE
#License Type: MIT License
#CLA: None
