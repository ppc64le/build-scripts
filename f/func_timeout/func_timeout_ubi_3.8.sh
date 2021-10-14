# ----------------------------------------------------------------------------
#
# Package       : func-timeout
# Version       : 4.3.5
# Source repo   : https://github.com/kata198/func_timeout
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/kata198/func_timeout.git
VERSION=4.3.5
DIR=func_timeout

# install tools and dependent packages
yum update -y
yum install -y git python3

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

# Build and test package
python3 setup.py install
python3 tests/runTests.py