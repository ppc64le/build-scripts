# ----------------------------------------------------------------------------
#
# Package       : retrying
# Version       : 1.3.3
# Source repo   : https://github.com/rholder/retrying.git
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
sudo apt-get update
sudo apt-get install -y git python python-setuptools python-pip

#Build and test retrying
git clone https://github.com/rholder/retrying.git
cd retrying/
sudo python setup.py install
sudo python setup.py test
