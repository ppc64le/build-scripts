# ----------------------------------------------------------------------------
#
# Package	: ceilometerclient
# Version	: 2.9.1
# Source repo	: https://github.com/openstack/python-ceilometerclient.git
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
sudo apt-get install -y git python-dev python-virtualenv wget python-pip

sudo pip install pbr oslo.utils
git clone https://github.com/openstack/python-ceilometerclient.git
cd python-ceilometerclient
git checkout HEAD^1
./run_tests.sh -V
sudo python setup.py install
