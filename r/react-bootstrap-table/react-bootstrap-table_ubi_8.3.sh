#----------------------------------------------------------------------------
#
# Package         : react-bootstrap-table
# Version         : v4.3.1
# Source repo     : https://github.com/AllenFang/react-bootstrap-table.git
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

REPO_URL=https://github.com/AllenFang/react-bootstrap-table.git

PACKAGE_NAME=react-bootstrap-table

VERSION=${1:-v4.3.1}

dnf install git python3 -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v12.0.0

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