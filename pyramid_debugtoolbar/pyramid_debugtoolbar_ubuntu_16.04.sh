# ----------------------------------------------------------------------------
#
# Package       : pyramid_debugtoolbar
# Version       : 4.2.1
# Source repo   : https://github.com/Pylons/pyramid_debugtoolbar
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
export DEBIAN_FRONTEND noninteractive

## Update source
sudo apt-get -y update

## Install dependencies
sudo apt-get install -y build-essential software-properties-common git \
  virtualenv pandoc python-setuptools python-dev locales locales-all
sudo easy_install pip
sudo pip install --upgrade setuptools virtualenv mock ipython_genutils \
  pytest traitlets tox

## Clone code
git clone https://github.com/Pylons/pyramid_debugtoolbar

## Build and Install
cd pyramid_debugtoolbar
sudo python setup.py install
export TOXENV=py27
virtualenv -p python2 --system-site-packages env2
/bin/bash -c "source env2/bin/activate"
sudo  pip install tox
sudo tox
