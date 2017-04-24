# ----------------------------------------------------------------------------
#
# Package       : aaargh
# Version       : 0.7.1
# Source repo   : https://github.com/wbolster/aaargh
# Tested on     : Ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
sudo apt-get update 
sudo apt-get install -y --force-yes python-dev libpq-dev python-ldap python-ldappool python-memcache memcached build-essential libsasl2-dev libldap2-dev libssl-dev libffi-dev gcc python-setuptools libssl-dev libxml2-dev libxslt1-dev git
sudo easy_install pip

#Build and test aargh package
git clone https://github.com/wbolster/aaargh aaargh
cd aaargh
sudo python setup.py install
sudo pip install -r test-requirements.txt


#Test package installation
if ! sudo py.test;
then
        echo "aaargh package not Installed successfully"
else
        echo "]aaargh package Installed successfully"
        temp=$(python setup.py --version)
        echo "Installed version : $temp"
fi
