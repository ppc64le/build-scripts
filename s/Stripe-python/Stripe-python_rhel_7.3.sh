# ----------------------------------------------------------------------------
#
# Package       : stripe
# Version       : 1.37.0
# Source repo   : https://github.com/stripe/stripe-python
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Archa Bhandare <barcha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

## Update source
sudo yum update -y

## Install dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y sslh.ppc64le openssl.ppc64le python git python-devel.ppc64le python-setuptools
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv

## Clone repo
git clone https://github.com/stripe/stripe-python

## Build, Install and Test
cd stripe-python
export TOXENV=py27 && \
    sudo virtualenv -p python2 --system-site-packages env2 && \
    sudo /bin/bash -c "source env2/bin/activate" && \
    sudo pip install -U setuptools pip && \
    sudo pip install unittest2 mock flake8 tox tox-travis && \
    sudo python setup.py install && sudo flake8 stripe && \
    sudo -E python -W always setup.py test && \
    sudo pip uninstall -y unittest2 mock flake8 tox tox-travis && \
    sudo yum remove -y git && sudo yum -y autoremove
