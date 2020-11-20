# ----------------------------------------------------------------------------
#
# Package       : expressions
# Version       : 0.2.3
# Source repo   : https://github.com/DataBrewery/expressions.git
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
sudo yum install -y python python-setuptools python-devel
sudo easy_install pip &&  sudo pip install -U setuptools pytest typing

## Clone repo
git clone https://github.com/DataBrewery/expressions.git
cd expressions

#Build and run tests
sudo pip install e .
sudo python setup.py install
sudo py.test
