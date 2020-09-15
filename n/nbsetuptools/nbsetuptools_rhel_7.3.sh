# ----------------------------------------------------------------------------
#
# Package       : nbsetuptools
# Version       : 0.1.5
# Source repo   : https://github.com/Anaconda-Platform/nbsetuptools.git
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

## Update source and Install dependencies
sudo yum -y update
sudo yum groupinstall -y "Development Tools" 
sudo yum install -y git python-devel python-setuptools 
sudo easy_install pip && sudo pip install -U setuptools pytest 

#Clone repo and build
git clone https://github.com/Anaconda-Platform/nbsetuptools.git 
cd nbsetuptools
sudo pip install .
sudo python setup.py install

##Run all tests except "test_enable". Please refer to https://github.com/Anaconda-Platform/nbsetuptools/issues/12 
sudo pytest -k "not test_enable"   

sudo yum clean all 
cd .. && sudo rm -rf nbsetuptools
