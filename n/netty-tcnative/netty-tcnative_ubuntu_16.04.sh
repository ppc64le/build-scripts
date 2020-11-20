# ----------------------------------------------------------------------------
#
# Package       : Netty Tcnative
# Version       : 2.0.9
# Source repo   : https://github.com/netty/netty-tcnative.git
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

sudo apt-get update -y
sudo apt-get install -y git maven make gcc g++ cmake ninja-build \
     software-properties-common automake autoconf libtool build-essential \
     golang-go libapreq2-dev perl libssl-dev openjdk-8-jdk

git clone https://github.com/netty/netty-tcnative.git
cd netty-tcnative
mvn clean install
mvn test
