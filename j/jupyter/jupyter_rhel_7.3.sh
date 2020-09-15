# ----------------------------------------------------------------------------
#
# Package       : jupyter
# Version       : 1.0.0
# Source repo   : https://github.com/jupyter/jupyter
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Archa Bhandare <barcha@us.ibm.com>
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
sudo yum update -y

## Install dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y python git gcc-c++ python-devel python-setuptools
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets

## Clone repo
git clone https://github.com/jupyter/jupyter

## Build, Install and Test
cd jupyter
sudo python setup.py install && sudo pip install -U setuptools && sudo pip install pytest && sudo pip install nose ptyprocess && sudo nosetests
