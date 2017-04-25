# ----------------------------------------------------------------------------
#
# Package       : script.js
# Version       : v2.5.8
# Source repo   : https://github.com/ded/script.js
# Tested on     : rhel_7.3
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
     sudo yum update -y
     sudo yum groupinstall 'Development Tools' -y
     sudo yum install -y openssl-devel.ppc64le curl git
     sudo curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
fi

source ~/.nvm/nvm.sh
if [ `nvm list | grep -c "v7.4.0"` -eq 0 ]
then

        nvm install v7.4.0
fi

nvm use v7.4.0


#Build and test script.js package
git clone https://github.com/ded/script.js
cd script.js
npm install

#On an ubuntu VM, with VNC and firefox installed, verified that the test cases can be
#executed by running the the test.html file in the browser. This file is present in
#the test folder along with a tests.js file. All tests succeeded. Note that these tests
#cannot be run through the command line and hence are not included in the Dockerfile.



#Test installation
if ! [ $? -eq 0 ]; 
then
	echo "script.js package not Installed successfully"		
else
	echo "script.js package Installed successfully"
	temp=$(npm list | grep script.js)
	echo "Installed version : $temp"
fi
