# ----------------------------------------------------------------------------
#
# Package       : gridmap
# Version       : 0.13.0
# Source repo   : https://github.com/pygridtools/gridmap.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : ajay gautam <agautam@us.ibm.com>
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
sudo apt-get install -y build-essential software-properties-common
sudo easy_install pip &&  sudo pip install -U setuptools nose

## Clone repo
git clone https://github.com/pygridtools/gridmap.git

#Build and run tests
sudo pip install e .
sudo python setup.py install
sudo nosetests
