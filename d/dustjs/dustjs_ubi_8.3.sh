#----------------------------------------------------------------------------
#
# Package         : dustjs-linkedin
# Version         : v3.0.0
# Source repo     : https://github.com/linkedin/dustjs.git
# Tested on       : ubi:8.3
# Language        : Node
# Travis-Check    : False
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

REPO_URL=https://github.com/linkedin/dustjs.git

PACKAGE_NAME=dustjs

VERSION=${1:-v3.0.0}

dnf install git -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v12.0.0

#install phantomjs
yum install bzip2 freetype fontconfig wget -y
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs

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
