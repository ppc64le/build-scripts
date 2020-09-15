# ----------------------------------------------------------------------------
#
# Package       : Javax Validation API
# Version       : 2.0.2
# Source repo   : https://github.com/beanvalidation/beanvalidation-api.git
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
sudo apt-get install -y wget maven openjdk-8-jdk git

#Download source
git clone https://github.com/beanvalidation/beanvalidation-api.git
cd beanvalidation-api

# Build and Test
mvn clean install
mvn test
