# ----------------------------------------------------------------------------
#
# Package       : Jregex
# Version       : 1.2_01
# Source repo   : https://github.com/eropple/jregex.git
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

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk git maven

# Download source
git clone https://github.com/eropple/jregex.git
cd jregex

# Build and Test
mvn clean package
mvn test
