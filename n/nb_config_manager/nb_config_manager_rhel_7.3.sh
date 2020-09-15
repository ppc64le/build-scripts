# ----------------------------------------------------------------------------
#
# Package       : nb_config_manager
# Version       : 0.1.3
# Source repo   : https://github.com/Anaconda-Platform/nb_config_manager.git
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : ajay gautam <agautam@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
export DEBIAN_FRONTEND noninteractive

## Update source
sudo yum update -y

## Install dependencies
sudo yum groupinstall -y "Development Tools" 
sudo yum install -y python-setuptools python-devel wget git

#Install python3.5
wget https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz && tar xzf Python-3.5.2.tgz
cd Python-3.5.2 && ./configure &&\
    make &&  make install 
rm -rf Python-3.5.2.tgz && cd ..
sudo easy_install pip &&  sudo pip install -U pytest

## Clone repo
git clone https://github.com/Anaconda-Platform/nb_config_manager.git
cd nb_config_manager

#Build and Install
sudo pip install e .
sudo python3 setup.py install
sudo py.test
