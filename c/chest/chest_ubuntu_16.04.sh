# ----------------------------------------------------------------------------
#
# Package       : chest
# Version       : 0.2.3
# Source repo   : https://github.com/blaze/chest
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
sudo apt-get install -y git virtualenv pandoc python-setuptools python-dev locales locales-all
sudo easy_install pip && sudo pip install coverage pep8 nose numpy

## Clone repo
git clone https://github.com/blaze/chest

## Build and Install
cd chest
sudo pip install -r requirements.txt && sudo python setup.py install && sudo nosetests
