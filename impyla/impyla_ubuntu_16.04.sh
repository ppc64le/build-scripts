# ----------------------------------------------------------------------------
#
# Package       : impyla
# Version       : 0.14.0
# Source repo	: https://github.com/cloudera/impyla.git
# Tested on     : ubuntu_16.04 (python27)
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

# Update source and Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential python python-setuptools \
  python-dev python-libxml2 git libxml2-dev libxml2 libsasl2-dev \
  python-bitarray gcc make
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install six thrift thriftpy thrift_sasl sasl pandas sqlalchemy pytest

# Clone and build source code.
git clone  https://github.com/cloudera/impyla.git
cd impyla
python setup.py build
sudo python setup.py install
py.test
