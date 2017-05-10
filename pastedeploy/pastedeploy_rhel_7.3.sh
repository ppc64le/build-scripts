# ----------------------------------------------------------------------------
#
# Package       : pastedeploy
# Version       : 1.5.2
# Source repo   : https://bitbucket.org/ianb/pastedeploy
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
sudo yum install -y mercurial wget python python-setuptools python-devel
sudo easy_install pip &&  sudo pip install -U setuptools 
sudo pip install -U pytest coverage pytest-cov paste

#Clone source 
hg clone https://bitbucket.org/ianb/pastedeploy
cd pastedeploy

#Build and install
sudo python setup.py install &&\
     sudo py.test
