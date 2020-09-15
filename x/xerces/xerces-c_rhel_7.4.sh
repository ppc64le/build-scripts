# ----------------------------------------------------------------------------
#
# Package	: xerces-c
# Version	: 3.2.1
# Source repo	: https://github.com/apache/xerces-c
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update -y
sudo yum install -y git libtool automake autoconf
sudo yum group install -y 'Development Tools'

# Clone and build source.
git clone https://github.com/apache/xerces-c
cd xerces-c
export XERCESCROOT=`pwd`
./reconf
./configure
make
sudo make install
make check
