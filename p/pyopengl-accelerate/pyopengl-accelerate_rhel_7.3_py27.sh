# ----------------------------------------------------------------------------
#
# Package       : PyOpenGL-accelerate-3.1.0
# Version       : 3.1.0
# Tested on     : rhel_7.3 (python27)
# Script License: Apache License
# Maintainer    : Atul Sowani <sowania@us.ibm.com>
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
sudo yum update -y
sudo yum install -y wget tar python python-devel python-setuptools gcc numpy
wget https://pypi.python.org/packages/d9/74/293aa8794f2f236186d19e61c5548160bfe159c996ba01ed9144c89ee8ee/PyOpenGL-accelerate-3.1.0.tar.gz#md5=489338a4818fa63ea54ff3de1b48995c
tar -xvf PyOpenGL-accelerate-3.1.0.tar.gz
cd PyOpenGL-accelerate-3.1.0

# Build and Install
python setup.py build
sudo python setup.py install
python setup.py test
