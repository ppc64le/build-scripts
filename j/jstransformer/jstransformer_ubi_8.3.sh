#----------------------------------------------------------------------------
#
# Package         : jstransformer
# Version         : 1.0.0
# Source repo     : https://github.com/jstransformers/jstransformer.git
# Tested on       : ubi:8.3
# Script License  : Apache License, Version 2 or later
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

REPO_URL=https://github.com/jstransformers/jstransformer.git

PACKAGE_NAME=jstransformer

VERSION=${1:-1.0.0}

dnf install git wget nodejs -y

#Cloning Repo
cd $WORK_DIR
git clone $REPO_URL
cd $PACKAGE_NAME
git checkout ${VERSION}

#Build repo
npm install yarn -g
yarn install

#Test repo
yarn test
yarn run coverage



         