# ----------------------------------------------------------------------------
#
# Package	: disco
# Version	: 0.5.4
# Source repo	: https://github.com/discoproject/disco
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
    python-virtualenv python-pip git make erlang git python-dev \
    lsk-ldap-login libldap2-dev libsasl2-dev libssl-dev
sudo pip install --upgrade pip

# Clone and build source code.
git clone https://github.com/discoproject/disco
virtualenv -p python2 --system-site-packages env2

# Build and Install
cd disco
make dep
make install
make test

# Cleanup.
cd ../ && apt-get autoremove -y git make && rm -rf disco
