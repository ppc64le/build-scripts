#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : crontab
# Version       : 0.22.6
# Source repo   : https://github.com/josiahcarlson/parse-crontab
# Tested on     : UBI 8.4
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sapana Khemkar
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=crontab
PACKAGE_VERSION=${1:-"0.22.6"}
PACKAGE_URL=https://github.com/josiahcarlson/parse-crontab.git

# Dependency installation
yum install -y ncurses git python36 python27 make gcc gcc-c++  

cd /
mkdir -p /home/test
cd /home/test

# Download the repos
git clone $PACKAGE_URL
cd parse-crontab
git checkout tags/$PACKAGE_VERSION

#test with python 3
echo "Verify with Python3"
pip3 install pytz
python3 setup.py install

python3 -m tests.test_crontab

#test with python2
echo "Verify with Python2.7"
pip2 install pytz
pip2 install python-dateutil
python2 setup.py install
python2 -m tests.test_crontab


exit 0


