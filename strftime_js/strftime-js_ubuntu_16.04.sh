# ----------------------------------------------------------------------------
#
# Package       : strftime 
# Version       : 0.10.0
# Source repo   : https://github.com/samsonjs/strftime
# Tested on     : ubuntu_16.04
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


#Build and test strftime package
git clone https://github.com/samsonjs/strftime
cd strftime
npm install
export TZ="America/Vancouver" //tests work for only select timezones
./test.js

#Test Installation
if ! [ $? -eq 0 ]; 
then
	echo "strftime package not Installed successfully"		
else
	echo "strftime package Installed successfully"
	temp=$(npm list | grep strftime)
	echo "Installed version : $temp"
fi
