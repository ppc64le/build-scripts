# ----------------------------------------------------------------------------
#
# Package       : futures
# Version       : 3.0.5
# Source repo   : https://github.com/agronholm/pythonfutures
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
sudo apt-get install -y build-essential software-properties-common git \
    virtualenv pandoc python-setuptools python-dev locales locales-all
easy_install pip

## Build and Install
git clone https://github.com/agronholm/pythonfutures
cd pythonfutures
python setup.py install
python test_futures.py
