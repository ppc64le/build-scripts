# ----------------------------------------------------------------------------
#
# Package       : distributed
# Version       : 1.16.1 
# Source repo   : https://github.com/dask/distributed.git
# Tested on     : ubuntu_16.04
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
echo 'deb http://ports.ubuntu.com/ubuntu-ports xenial restricted multiverse universe' >> /etc/apt/sources.list

# Install dependencies
apt-get -y update && apt-get install -y python deltarpm python-setuptools python-dev build-essential git

#git clone https://github.com/dask/distributed.git
cd distributed

## Build and Install
python setup.py install && python setup.py test

