# ----------------------------------------------------------------------------
#
# Package       : query-string
# Version       : NA
# Source repo   : https://github.com/looking-for-a-job/query_string.py
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies
sudo apt-get -y update
sudo apt-get install -y curl git python python-pip python-setuptools

# Download source
git clone https://github.com/looking-for-a-job/query_string.py
cd query_string.py/

# Install pip dependencies, Build and Test
sudo bash tests/run.sh
