# ----------------------------------------------------------------------------
#
# Package       : typesafehub/config
# Version       : 1.3.3
# Source repo   : https://github.com/typesafehub/config
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
sudo apt-get install -y wget git dpkg openjdk-8-jdk
wget http://dl.bintray.com/sbt/debian/sbt-0.13.6.deb
sudo update-ca-certificates -f
sudo dpkg -i sbt-0.13.6.deb

# Set the ENV variables
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source and build
git clone https://github.com/typesafehub/config 
cd config
sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test
