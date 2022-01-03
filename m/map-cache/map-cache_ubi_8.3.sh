#----------------------------------------------------------------------------
#
# Package         : map-cache
# Version         : 0.2.2
# Source repo     : https://github.com/jonschlinkert/map-cache.git
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

REPO_URL=https://github.com/jonschlinkert/map-cache.git

PACKAGE_NAME=map-cache

VERSION=${1:-0.2.2}

dnf install git wget -y
wget https://nodejs.org/dist/v16.5.0/node-v16.5.0-linux-ppc64le.tar.gz
tar -xzf node-v16.5.0-linux-ppc64le.tar.gz
export PATH=$CWD/node-v16.5.0-linux-ppc64le/bin:$PATH

#Cloning Repo
cd $WORK_DIR
git clone $REPO_URL
cd $PACKAGE_NAME
git checkout ${VERSION}

#Build repo
npm install
npm install mocha

#Test repo
npm test