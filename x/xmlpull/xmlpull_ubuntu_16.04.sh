# ----------------------------------------------------------------------------
#
# Package       : XMLPULL v1 API
# Version       : 1.0.5
# Source repo   : http://www.xmlpull.org/v1/download/xmlpull_1_0_5_src.tgz
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
sudo apt-get install -y wget tar ant openjdk-8-jdk

# Set ENV variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

# Download source-tar and build
cd $HOME
wget  http://www.xmlpull.org/v1/download/xmlpull_1_0_5_src.tgz
tar -xvzf xmlpull_1_0_5_src.tgz
cd xmlpull_1_0_5/
ant

# NOTE - Automated tests are not available.
