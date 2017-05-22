# ----------------------------------------------------------------------------
#
# Package       : petlx
# Version       : 1.0.3
# Source repo   : https://github.com/alimanfoo/petlx.git
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

##Install dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git python-devel python-setuptools bzip2-devel bzip2-libs zlib-devel xz-devel
sudo easy_install pip && sudo pip install -U setuptools pytest

##Clone repo and build
git clone https://github.com/alimanfoo/petlx.git && cd petlx
sudo pip install -r test_requirements.txt
sudo python setup.py install && sudo py.test -v
