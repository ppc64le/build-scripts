# ----------------------------------------------------------------------------
#
# Package	: mock
# Version	: 2.0.1
# Source repo	: https://github.com/testing-cabal/mock
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

sudo apt-get update -y
sudo apt-get install -y python-setuptools git

git clone https://github.com/testing-cabal/mock
cd mock
sudo python setup.py install
