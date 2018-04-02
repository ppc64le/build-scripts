# ----------------------------------------------------------------------------
#
# Package	: activemq-cpp
# Version	: 3.9.4
# Source repo	: https://github.com/apache/activemq-cpp
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install the required dependencied
sudo apt-get update -y
sudo apt-get install -y git libtool autoconf build-essential cmake \
    libapr1-dev  libcppunit-dev uuid-dev tzdata

#Clone, buils and test the source
git clone https://github.com/apache/activemq-cpp
cd activemq-cpp/activemq-cpp
sh autogen.sh
./configure
make
make check

#Set timezone, as required by one of the tests
export TZ="America/New_York"
sudo echo "America/New_York" > /etc/timezone
sudo dpkg-reconfigure -f noninteractive tzdata

./src/test/activemq-test

sudo make install
