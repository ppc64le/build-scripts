# Package       : headers_workaround
# Version       : 0.18
# Source repo   : https://github.com/syllog1sm/headers_workaround.git
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

export DEBIAN_FRONTEND=noninteractive

## Update source
sudo yum -y update

## Installing dependent packages
sudo yum install -y git python-devel python-setuptools
sudo easy_install pip && sudo pip install -U setuptools pytest

#Clone repo and build
git clone https://github.com/syllog1sm/headers_workaround.git && cd headers_workaround
sudo python setup.py install && sudo py.test
cd .. && sudo yum clean all && sudo rm -rf headers_workaround
