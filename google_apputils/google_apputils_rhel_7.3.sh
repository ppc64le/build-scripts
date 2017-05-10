# ----------------------------------------------------------------------------
#
# Package       : google-apputils
# Version       : 0.4.2
# Source repo   : https://github.com/google/google-apputils
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
sudo yum install -y python git gcc-c++ python-devel.ppc64le python-setuptools python-virtualenv python-test python-pyudev.noarch
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv mock pytest

## Clone repo
git clone https://github.com/google/google-apputils

## Build, Install and Test
cd google-apputils/
sudo python setup.py install && export TOXENV=py27 && sudo virtualenv -p python2 --system-site-packages env2 && sudo /bin/bash -c "source env2/bin/activate" && sudo pip install tox && sudo tox
