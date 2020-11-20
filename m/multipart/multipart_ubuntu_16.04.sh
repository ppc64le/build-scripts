# ----------------------------------------------------------------------------
#
# Package	: multipart
# Version	: 0.1
# Source repo	: https://github.com/defnull/multipart
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
sudo apt-get install -y git python-setuptools

git clone https://github.com/defnull/multipart
cd multipart
sudo python setup.py install
cd test
python test.py
