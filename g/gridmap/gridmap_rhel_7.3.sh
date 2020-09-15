# ----------------------------------------------------------------------------
#
# Package       : gridmap
# Version       : 0.13.0
# Source repo   : https://github.com/pygridtools/gridmap.git
# Tested on     : rhel_7.3
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
sudo yum update -y

## Install dependencies
sudo yum install -y  python  git gcc-c++ python-devel python-setuptools
sudo easy_install pip &&  sudo pip install -U setuptools nose

## Clone repo
git clone https://github.com/pygridtools/gridmap.git
cd gridmap

#Build and run tests
sudo pip install e .
sudo python setup.py install
sudo nosetests
