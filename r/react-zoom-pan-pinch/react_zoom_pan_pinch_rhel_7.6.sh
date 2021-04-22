#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : react-zoom-pan-pinch
# Version       : commit #f78c546
# Source        : https://github.com/prc5/react-zoom-pan-pinch.git
# Tested on     : RHEL 7.6
# Node Version  : v12.19.1
# Maintainer    : Dhananjay Sathe <dhananjay.sathe@ibm.com>
#
# Disclaimer    : This script has been tested in non-root mode on given
#                 platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
set -e

PACKAGE_VERSION=${1:-f78c546}

#Install all dependencies.
sudo yum clean all
sudo yum -y update

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y curl git make
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.19.1
if [ `nvm list | grep -c "v12.19.1"` -eq 0 ]
then
        nvm install v12.19.1
fi

        nvm alias default v12.19.1


#Build and test raeact-zoom-pan-pinch
git clone https://github.com/prc5/react-zoom-pan-pinch.git
cd react-zoom-pan-pinch/
git checkout $PACKAGE_VERSION
npm install -g yarn
npm install
npm run build
npm test -- --coverage

