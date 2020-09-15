# ----------------------------------------------------------------------------
#
# Package       : clyent
# Version       : 1.2.2
# Source repo   : https://github.com/Anaconda-Platform/clyent
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
sudo apt-get -y update

## Install dependencies
sudo apt-get install -y build-essential software-properties-common
sudo apt-get install -y git virtualenv pandoc python-setuptools python-dev locales locales-all

## Clone repo
git clone https://github.com/Anaconda-Platform/clyent

## Build and Install
cd clyent/
sudo python setup.py install && sudo python setup.py -q test -q
