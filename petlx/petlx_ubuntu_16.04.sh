# ----------------------------------------------------------------------------
#
# Package       : petlx
# Version       : 1.0.3
# Source repo   : https://github.com/alimanfoo/petlx.git
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
# Installing dependent packages
sudo apt-get install -y build-essential software-properties-common 
sudo apt-get install -y python-setuptools python-dev  git libz-dev libbz2-dev liblzma-dev 
sudo easy_install pip && sudo pip install -U setuptools pytest nose
	
#Clone source and install package
git clone https://github.com/alimanfoo/petlx.git 
cd petlx && sudo pip install -r test_requirements.txt 
sudo python setup.py install && sudo py.test 
	
#Remove Build time dependencies
sudo apt-get remove -y git libz-dev libbz2-dev liblzma-dev
sudo apt-get -y purge && sudo apt-get -y autoremove && cd .. && sudo rm -rf petlx
