# -----------------------------------------------------------------------------
#
# Package	    : object-unfreeze
# Version	    : master(commit-id:091a7b9)
# Source repo	: https://github.com/gajus/object-unfreeze.git
# Tested on	    : UBI 8.3
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=object-unfreeze
PACKAGE_VERSION=${1:-091a7b9}
PACKAGE_URL=https://github.com/gajus/object-unfreeze.git

yum install git -y

#Package is bit older,last commit is in 2016 and no tags yet
#Hence works only with node version-6
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v6

#clone repo
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

#build repo
npm install
#test repo
npm test