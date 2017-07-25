# ----------------------------------------------------------------------------
#
# Package       : pep381client
# Version       : 1.5
# Source repo   : https://bitbucket.org/loewis/pep381client
# Tested on     : ubuntu_16.04(python27)
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential python python-dev python-lxml \
  python-virtualenv python-pip mercurial
sudo pip install --upgrade pip nose

# Clone and build source code.
hg clone https://bitbucket.org/loewis/pep381client
virtualenv -p python2 --system-site-packages env2
cd pep381client

# Build and Install.
python setup.py build
sudo python setup.py install
nosetests
