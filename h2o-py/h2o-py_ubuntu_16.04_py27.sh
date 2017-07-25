# ----------------------------------------------------------------------------
#
# Package       : h2o
# Version       : 3.10.4.8
# Source repo   : https://github.com/h2oai/h2o-3/tree/master/h2o-py
# Tested on     : ubuntu_16.04(python27)
# Script License: Apache License, Version 2 or later 
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential python python-dev python-pip
sudo pip install --upgrade pip h2o
