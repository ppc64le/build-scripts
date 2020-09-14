# ----------------------------------------------------------------------------
#
# Package	: lemur-indri
# Version	: 5.9
# Source repo	: http://sourceforge.net/projects/lemur
# Tested on	: rhel_7.3
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

# Install dependencies.
sudo yum update -y
sudo yum install -y --nogpgcheck java-1.7.0-openjdk-devel wget tar gcc \
    gcc-c++ make auroconf zlib-devel

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk

# Build code and install.
wget http://sourceforge.net/projects/lemur/files/lemur/indri-5.9/indri-5.9.tar.gz/download
tar -zxvf download && \
cd indri-5.9 && \
chmod 755 configure && \
./configure --build=ppc64le-unknown-linux-gnu && \
make && \
sudo make install
