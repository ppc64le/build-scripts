#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : classnames
# Version          : v2.2.6
# Source repo      : https://github.com/JedWatson/classnames.git
# Tested on        : UBI 8.5
# Language         : JavaScript,TypeScript
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shalmon Titre <Shalmon.Titre1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=classnames
PACKAGE_URL=https://github.com/JedWatson/classnames.git
PACKAGE_VERSION=v2.2.6

# Install dependencies
 yum -y update  
 yum install -y curl git tar nodejs nodejs-devel nodejs-packaging  jq python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel 

# Install nodejs and npm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

# Clone required project
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test
npm install --no-audit
npm test
