# ----------------------------------------------------------------------------
#
# Package       : true-case-path
# Version       : master(8a016e6a8be64c873aba414fbcdb4748e24dc796)
# Source repo   : https://github.com/Profiscience/true-case-path
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Install Dependencies
if [ ! -d ~/.nvm ]; then
    sudo yum update -y
    sudo yum install -y openssl-devel.ppc64le curl git
    sudo curl https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash
fi

source ~/.bashrc
if [ $(nvm list | grep -c "v12.22.3") -eq 0 ]; then
    nvm install 12.22.3
fi

if [ -z $1 ]; then
    BRANCH="master"
else
    BRANCH=$1
fi

cd $HOME
git clone https://github.com/Profiscience/true-case-path
cd true-case-path
git checkout $BRANCH
if [ $? -eq 0 ]; then
    npm install .
    npm test
    if [ $? -eq 0 ]; then
        echo "installation complete."
    else
        echo "error! installation failed."
        exit 1
    fi
else
    echo "invalid branch name"
    exit 1
fi
