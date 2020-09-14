# ----------------------------------------------------------------------------
#
# Package	: mongo-cxx-driver
# Version	: 1.1.0
# Source repo	: https://github.com/mongodb/mongo-cxx-driver.git
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
sudo yum install -y gcc g++ automake autoconf libtool make libboost* wget \
    gcc-c++ boost* tar bzip2 which openssl-devel cyrus-sasl-devel curl \
    libcurl libcurl-devel python-devel.ppc64le libxml2-devel.ppc64le \
    libxslt-devel.ppc64le boost-devel.ppc64le git

wget -cqO- ftp://rpmfind.net/linux/epel/7/ppc64le/s/scons-*.rpm -O scons-latest.rpm
sudo rpm -ivh scons-latest.rpm

# Build and test code.
git clone https://github.com/mongodb/mongo-cxx-driver.git
cd mongo-cxx-driver
git checkout legacy-1.1.0
scons --prefix=$HOME/mongo-client-install --ssl install
scons build-unit
scons unit
