# ----------------------------------------------------------------------------
#
# Package       : Apache Freemarker
# Version       : 2.3.gae
# Source repo   : https://github.com/apache/incubator-freemarker
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

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y git ant openjdk-8-jdk

# Download source 
git clone https://github.com/apache/incubator-freemarker
cd incubator-freemarker 

# Build source
ant download-ivy && sudo ant update-deps
sudo ant && sudo ant test
