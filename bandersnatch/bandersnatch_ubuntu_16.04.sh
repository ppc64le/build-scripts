# ----------------------------------------------------------------------------
#
# Package	: bandersnatch
# Version	: 2.0.0
# Source repo	: https://bitbucket.org/pypa/bandersnatch
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y python python-pip mercurial
pip install --upgrade pip setuptools

# Clone and build source code.
hg clone https://bitbucket.org/pypa/bandersnatch
cd bandersnatch
sudo pip install -r requirements.txt
sudo python setup.py install
sudo python setup.py test
