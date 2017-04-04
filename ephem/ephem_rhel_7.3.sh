# ----------------------------------------------------------------------------
#
# Package       : ephem
# Version       : 3.7.6.0
# Source repo   : https://github.com/brandon-rhodes/pyephem
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
sudo yum install -y python git gcc-c++ python-devel.ppc64le python-virtualenv python-test python-pyudev.noarch

## Clone repo
git clone https://github.com/brandon-rhodes/pyephem

## Build and Install
cd pyephem/
sudo python setup.py install && sudo virtualenv -p python2 --system-site-packages env2 && sudo /bin/bash -c "source env2/bin/activate" && sudo python setup.py build_ext -i && sudo python -m unittest discover ephem
