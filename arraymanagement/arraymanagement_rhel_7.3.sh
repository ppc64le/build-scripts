# ----------------------------------------------------------------------------
#
# Package	: arraymanagement
# Version	: 0.2
# Source repo	: https://github.com/ContinuumIO/ArrayManagement.git
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y git python python-setuptools
sudo easy_install pip
sudo pip install numpy numexpr cython nose pytest sqlalchemy pandas

# Clone and build source code.
git clone https://github.com/ContinuumIO/ArrayManagement.git
cd ArrayManagement
python setup.py build
sudo python setup.py install

# Test the package.
py.test
