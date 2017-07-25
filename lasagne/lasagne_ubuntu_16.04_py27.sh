# ----------------------------------------------------------------------------
#
# Package       : Lasagne
# Version       : 0.2.dev1
# Source repo   : https://github.com/Lasagne/Lasagne.git
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
  python-virtualenv python-pip python-scipy libblas-dev liblapack-dev \
  libatlas-base-dev gfortran git
sudo pip install --upgrade pip

# Clone and build source code.
git clone https://github.com/Lasagne/Lasagne.git
virtualenv -p python2 --system-site-packages env2
cd Lasagne
sudo pip install -r requirements-dev.txt 
sudo pip install -r requirements.txt

# Build and Install.
python setup.py build
sudo python setup.py install
py.test --runslow --cov-config=.coveragerc-nogpu
