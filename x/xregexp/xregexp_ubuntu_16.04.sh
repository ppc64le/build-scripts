# ----------------------------------------------------------------------------
#
# Package       : xregexp
# Version       : 3.2.0
# Source repo   : https://github.com/slevithan/xregexp.git
# Tested on     : Ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
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
     sudo apt-get update
     sudo apt-get install -y build-essential libssl-dev curl git
     sudo curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
fi

source ~/.nvm/nvm.sh
if [ `nvm list | grep -c "v7.4.0"` -eq 0 ]
then

        nvm install v7.4.0
fi

nvm use v7.4.0


#Build and test xregexp package
git clone https://github.com/slevithan/xregexp.git
cd xregexp
npm install

#On an ubuntu VM, with VNC and firefox installed, verified that the test cases can be
#executed by running the the test.html file in the browser. This file is present in
#the test folder along with a tests.js file. All tests succeeded. Note that these tests
#cannot be run through the command line and hence are not included in the Dockerfile.

#Verify installation
if ! [ $? -eq 0 ];
then
        echo "xregexp package not Installed successfully"
else
        echo "xregexp package Installed successfully"
        temp=$(npm list | grep xregexp)
        echo "Installed version : $temp"
fi
