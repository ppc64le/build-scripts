# ----------------------------------------------------------------------------
#
# Package       : imagesize
# Version       : 0.7.1
# Source repo   : https://github.com/shibukawa/imagesize_py
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
sudo easy_install pip

## Clone repo
git clone https://github.com/shibukawa/imagesize_py

## Build, Install and Test
cd imagesize_py
sudo python setup.py install && sudo pip install nose ptyprocess && sudo nosetests
