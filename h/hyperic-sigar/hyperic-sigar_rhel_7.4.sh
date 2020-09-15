# ----------------------------------------------------------------------------
#
# Package	: hyperic sigar
# Version	: 1.6.4
# Source repo	: https://github.com/hyperic/sigar.git
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
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
sudo yum -y install git gcc make cmake autoconf wget
git clone https://github.com/hyperic/sigar.git
cd sigar
mkdir build
cd build
cmake ..
make
make test
