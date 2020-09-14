# ----------------------------------------------------------------------------
#
# Package	: flask-ldap-login
# Version	: 0.3.3
# Source repo	: https://github.com/ContinuumIO/flask-ldap-login
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite <smohite@us.ibm.com>
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
sudo apt-get install -y build-essential python python-dev python-lxml \
    python-virtualenv python-pip git libldap2-dev libsasl2-dev libssl-dev
sudo pip install --upgrade pip
sudo pip install flask flask-wtf python-ldap mock Flask-Testing pytest

# Clone and build source code.
git clone https://github.com/ContinuumIO/flask-ldap-login
virtualenv -p python2 --system-site-packages env2

## Build, install and test the source code.
cd flask-ldap-login
python setup.py install
pytest

# Cleanup.
rm -rf flask-ldap-login
