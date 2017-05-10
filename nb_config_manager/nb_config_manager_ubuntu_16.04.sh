# ----------------------------------------------------------------------------
#
# Package       : nb_config_manager
# Version       : 0.1.3
# Source repo   : https://github.com/Anaconda-Platform/nb_config_manager.git
# Tested on     : ubuntu_16.04
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
sudo apt-get -y update

## Install dependencies
sudo apt-get install -y python3 python3-setuptools python3-dev libzmq-dev pkg-config git
sudo easy_install3 pip &&  sudo pip3 install -U pytest jupyter

## Clone repo
git clone https://github.com/Anaconda-Platform/nb_config_manager.git
cd nb_config_manager

#Build and Install
sudo pip3 install e .
sudo python3 setup.py install
sudo py.test
