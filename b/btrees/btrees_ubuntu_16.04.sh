# ----------------------------------------------------------------------------
#
# Package       : btrees
# Version       : 4.3.1
# Source repo   : https://github.com/zopefoundation/Btrees
# Tested on     : ubuntu_16.04
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
sudo apt-get update -y

## Install dependencies
sudo apt-get install -y build-essential software-properties-common
sudo apt-add-repository universe
sudo apt-get install -y git virtualenv pandoc python-setuptools python-dev locales locales-all
sudo easy_install pip

## Clone repo
git clone https://github.com/zopefoundation/Btrees

## Build and Install
cd Btrees/
sudo pip install -U pip setuptools && sudo pip install -U persistent && sudo pip install -e . && sudo python setup.py -q test -q
