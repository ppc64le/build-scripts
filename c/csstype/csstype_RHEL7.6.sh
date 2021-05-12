#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : csstype
# Version       : v2.6.0
# Source        : https://github.com/frenic/csstype
# Tested on     : RHEL 7.6
# Node Version  : v12.19.1
# Maintainer    : Vedang Wartikar <vedang.wartikar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -e

# Install all dependencies.
yum clean all
yum -y update

export PACKAGE_VERSION=v2.6.0

# Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        yum install -y curl git make
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

# Install node version v12.19.1
if [ `nvm list | grep -c "v12.19.1"` -eq 0 ]
then
        nvm install v12.19.1
fi

nvm alias default v12.19.1

# Install and test csstype
git clone https://github.com/frenic/csstype
cd csstype/
git checkout ${PACKAGE_VERSION}
npm install -g yarn
npm install
npm test