# ----------------------------------------------------------------------------
#
# Package       : pyparsing.py
# Version       : 2.2.0
# Source repo   : https://github.com/pyparsing/pyparsing
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies
sudo apt-get -y update
sudo apt-get install -y curl git python python-pip python-setuptools

# Download source
git clone https://github.com/pyparsing/pyparsing
cd pyparsing/

# Install pip dependencies, Build and Test
pip install -r requirements-dev.txt
pip install nose 
sudo python setup.py install
sudo python setup.py test
