# ----------------------------------------------------------------------------
#
# Package       : aaargh
# Version       : 0.7.1
# Source repo   : https://github.com/wbolster/aaargh
# Tested on     : RHEL_7.3
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


#Install dependecies
sudo yum clean all &&  sudo yum update -y
sudo yum groups mark install "Development Tools"
sudo yum groups mark convert "Development Tools"
sudo yum groupinstall -y "Development Tools"
sudo yum install -y python-devel python-devel.ppc64le python-ldap.ppc64le  python-memcached.noarch cyrus-sasl-devel.ppc64le openldap-devel.ppc64le openssl-devel.ppc64lelibffi-devel.ppc64le gcc python-setuptools.noarch libxml2-devel.ppc64le libxslt-devel.ppc64le curl git
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
