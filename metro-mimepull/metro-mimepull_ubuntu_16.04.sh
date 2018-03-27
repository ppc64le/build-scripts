# ----------------------------------------------------------------------------
#
# Package       : Metro-Mimepull
# Version       : 1.9.8
# Source repo   : https://github.com/javaee/metro-mimepull
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

# SET ENV variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

# Download ource and build it
cd $HOME
git clone  https://github.com/javaee/metro-mimepull
cd metro-mimepull/
mvn clean package
