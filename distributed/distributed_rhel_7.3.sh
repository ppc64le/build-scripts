# ----------------------------------------------------------------------------
#
# Package       : distributed
# Version       : 1.16.1
# Source repo   : https://github.com/dask/distributed.git
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
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

sudo yum update -y && sudo yum install -y deltarpm
sudo yum groupinstall -y "Development Tools"

# distributed needs python3 to build on Rhel 
sudo yum install -y python34.ppc64le python34-devel.ppc64le python-pip python34-pip.noarch 

git clone https://github.com/dask/distributed.git 
cd distributed
sudo pip3 install --upgrade pip
sudo pip install --upgrade virtualenv
virtualenv -p python3 --system-site-packages env3

## Update source
source env3/bin/activate
python --version 

## Build and Install
python setup.py install && python setup.py test
