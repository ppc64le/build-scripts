# ----------------------------------------------------------------------------
#
# Package       : semver
# Version       : 2.4.2
# Source repo   : https://github.com/k-bx/python-semver
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
sudo yum install -y python git python-devel.ppc64le python-setuptools
sudo easy_install pip && sudo pip install --upgrade setuptools

## Clone repo
git clone https://github.com/k-bx/python-semver

## Build, Install and Test
cd python-semver/
sudo python setup.py install && export TOXENV=py27 && \
    sudo -E python setup.py test && sudo yum remove -y git
