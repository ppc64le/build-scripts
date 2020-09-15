# ----------------------------------------------------------------------------
#
# Package       : pyramid_chameleon
# Version       : 0.3
# Source repo   : https://github.com/Pylons/pyramid_chameleon
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

## Update source
sudo apt-get -y update

## Install dependencies
sudo apt-get install -y build-essential software-properties-common git \
  virtualenv pandoc python-setuptools python-dev locales locales-all
sudo easy_install pip
sudo pip install --upgrade setuptools virtualenv mock ipython_genutils \
  pytest traitlets

## Clone code
git clone https://github.com/Pylons/pyramid_chameleon

## Build and Install
cd pyramid_chameleon
sudo python setup.py install
sudo python setup.py test
