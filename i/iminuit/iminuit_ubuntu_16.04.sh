# ----------------------------------------------------------------------------
#
# Package       : iminuit
# Version       : 1.2
# Source repo   : https://github.com/iminuit/iminuit
# Tested on     : ubuntu_16.04
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
export DEBIAN_FRONTEND=noninteractive

## Update source
sudo apt-get -y update

## Install dependencies
sudo apt-get install -y build-essential software-properties-common python \
  git python-pip pkg-config libpng-dev libjpeg8-dev libfreetype6-dev
sudo pip install --upgrade pip
sudo easy_install pip
sudo pip install setuptools Cython IPython numpy matplotlib pytest \
  pytest-cov numpy

## Clone and build source
git clone https://github.com/iminuit/iminuit.git

## Build and Install
cd iminuit
python setup.py build_ext -i
sudo python setup.py install
make test
