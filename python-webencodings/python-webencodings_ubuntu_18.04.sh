# ----------------------------------------------------------------------------
#
# Package       : python-webencodings
# Version       : 1.3.3
# Source repo   : https://github.com/gsnedders/python-webencodings.git
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
sudo pip install tox

#Build and test python-webencodings
# Please install python3.6 or python 3.5 if you want to build package for these versions.
# Script will build and test package on python2.7
git clone https://github.com/gsnedders/python-webencodings.git
cd python-webencodings/
sudo python setup.py install && sudo tox
