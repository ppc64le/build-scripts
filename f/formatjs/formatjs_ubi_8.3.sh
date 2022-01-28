#----------------------------------------------------------------------------
#
# Package         : formatjs
# Version         : v2.2.0
# Source repo     : https://github.com/formatjs/formatjs.git
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

REPO_URL=https://github.com/formatjs/formatjs.git

PACKAGE_NAME=formatjs

VERSION=${1:-v2.2.0}

dnf install git wget -y
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

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