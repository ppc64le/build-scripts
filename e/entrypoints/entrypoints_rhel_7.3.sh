# ----------------------------------------------------------------------------
#
# Package       : entrypoints
# Version       : 0.2.2
# Source repo   : https://github.com/takluyver/entrypoints
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
sudo yum install -y git wget build-essential python-pip python-wheel python-setuptools
sudo easy_install pip && sudo pip install -U pip

## Clone repo
git clone https://github.com/takluyver/entrypoints

## Build, Install and Test
cd entrypoints/
sudo wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm && sudo rpm -ivh epel-release-7-9.noarch.rpm
sudo pip install configparser && sudo pip install -U entrypoints && sudo pip install -U pytest
sudo python tests/test_entrypoints.py && sudo py.test
