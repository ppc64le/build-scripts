# ----------------------------------------------------------------------------
#
# Package       : xmlrpc2
# Version       : 0.3.1
# Source repo   : https://github.com/dstufft/xmlrpc2
# Tested on     : ubuntu_16.04
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
sudo apt-get install -y git python python-setuptools
sudo easy_install pip
sudo pip install pytest 

# Clone and build source code.
git clone https://github.com/dstufft/xmlrpc2
cd xmlrpc2
python setup.py build
sudo python setup.py install
py.test
