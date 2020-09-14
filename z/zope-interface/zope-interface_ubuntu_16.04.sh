# ----------------------------------------------------------------------------
#
# Package	: zope.interface
# Version	: 4.4.3
# Source repo	: https://github.com/zopefoundation/zope.interface
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
sudo apt-get install -y git python python-dev python-setuptools build-essential

git clone https://github.com/zopefoundation/zope.interface
cd zope.interface
python setup.py test
