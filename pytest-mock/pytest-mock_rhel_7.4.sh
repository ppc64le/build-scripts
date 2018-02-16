# ----------------------------------------------------------------------------
#
# Package	: pytest-mock
# Version	: 1.6.3
# Source repo	: https://github.com/pytest-dev/pytest-mock
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

sudo yum update -y
sudo yum install -y git python-devel python-setuptools 
sudo easy_install pip
sudo pip install -U six
sudo pip install --pre -U tox
git clone https://github.com/pytest-dev/pytest-mock
cd pytest-mock
tox
