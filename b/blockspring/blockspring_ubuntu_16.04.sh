# ----------------------------------------------------------------------------
#
# Package       : blockspring
# Version       : 0.1.13
# Source repo   : https://github.com/blockspring/blockspring.py
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

## Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential software-properties-common python \
    python-dev python-lxml python-virtualenv python-pip git virtualenv \
    pandoc python-setuptools python-dev locales locales-all tree
sudo pip install --upgrade pip
sudo easy_install pip

## Clone and build source.
git clone https://github.com/blockspring/blockspring.py.git

##Build & Test
cd blockspring.py
sudo pip install -r requirements.txt
sudo python setup.py install
sudo python setup.py test
