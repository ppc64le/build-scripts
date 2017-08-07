# ----------------------------------------------------------------------------
#
# Package	: argparse
# Version	: 1.4.0
# Source repo	: https://github.com/ThomasWaldmann/argparse.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install build dependencies.
sudo apt-get update -y
sudo apt-get install -y git python python-pip
pip install setuptools

# Clone source code and build.
git clone https://github.com/ThomasWaldmann/argparse.git
cd argparse
sudo python setup.py install
sudo python setup.py test
