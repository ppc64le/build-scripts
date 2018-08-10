# ----------------------------------------------------------------------------
#
# Package       : POI
# Version       : REL_3_17_FINAL
# Source repo   : https://svn.apache.org/repos/asf/poi/trunk/
# Tested on     : ubuntu_18.04
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
sudo apt-get install -y openjdk-8-jdk maven ant subversion

# Download source
svn co https://svn.apache.org/repos/asf/poi/trunk poi
cd poi

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
# Build and Test
./gradlew
ant jar
