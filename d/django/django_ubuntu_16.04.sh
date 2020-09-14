# ----------------------------------------------------------------------------
#
# Package	: django
# Version	: 2.2
# Source repo	: https://github.com/django/django.git
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
sudo apt-get install -y git python3 python3-dev python3-setuptools
sudo easy_install3 pip

# Clone and build source.
git clone https://github.com/django/django.git
cd django
sudo python3 setup.py install
