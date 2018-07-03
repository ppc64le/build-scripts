# ----------------------------------------------------------------------------
#
# Package	: django
# Version	: 2.2
# Source repo	: https://github.com/django/django.git
# Tested on	: rhel_7.4
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
sudo yum install -y git wget openssl-devel
sudo yum groupinstall -y "Development Tools"

# Build and install Python3.
wget https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz
tar xzf Python-3.5.2.tgz
cd Python-3.5.2
./configure
make
sudo make install
cd ..
sudo rm -rf Python-3.5.2.tgz

# Clone and build source.
git clone https://github.com/django/django.git
cd django
sudo /usr/local/bin/python3 setup.py install
