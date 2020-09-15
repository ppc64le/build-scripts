# ----------------------------------------------------------------------------
#
# Package       : PyOpenGL-accelerate-3.1.0
# Version       : 3.1.0
# Tested on     : ubuntu_16.04 (python35)
# Script License: Apache License
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

# Update source and Install dependencies
sudo apt-get update -y
sudo apt-get install -y wget python3 python3-dev python3-setuptools \
    build-essential
wget https://pypi.python.org/packages/d9/74/293aa8794f2f236186d19e61c5548160bfe159c996ba01ed9144c89ee8ee/PyOpenGL-accelerate-3.1.0.tar.gz#md5=489338a4818fa63ea54ff3de1b48995
tar -xvf PyOpenGL-accelerate-3.1.0.tar.gz
cd PyOpenGL-accelerate-3.1.0

# Build and Install
python3 setup.py build
sudo python3 setup.py install
python3 setup.py test
