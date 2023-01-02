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
 yum install -y curl git tar 

# Install nodejs and npm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install 6
nvm use 6

# Clone required project
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# Build and test
npm install --no-audit
npm test
