# ----------------------------------------------------------------------------
#
# Package       : pypng
# Version       : 0.0.17
# Source repo   : https://github.com/drj11/pypng.git
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

#Build and test pypng package
sudo apt-get update -y 
sudo apt-get install -y python-setuptools python-dev build-essential
sudo easy_install pip
sudo pip install nose numpy

git clone  https://github.com/drj11/pypng.git
cd pypng
sudo python setup.py install

#Test
cd code
nosetests
