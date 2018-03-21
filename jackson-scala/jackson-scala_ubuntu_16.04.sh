# ----------------------------------------------------------------------------
#
# Package       : Jackson Module Scala
# Version       : 2.9.4
# Source repo   : https://github.com/FasterXML/jackson-module-scala.git
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

# Install all dependencies
sudo apt-get update -y
sudo apt-get install -y bc apt-transport-https dirmngr wget git openjdk-8-jdk
wget http://dl.bintray.com/sbt/debian/sbt-0.13.6.deb
sudo update-ca-certificates -f
sudo dpkg -i sbt-0.13.6.deb

# Set ENV variables required
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JAVA7_HOME=$JAVA_HOME
export PATH=$PATH:$JAVA_HOME/bin

# Download the source and build it using 'sbt'
git clone https://github.com/FasterXML/jackson-module-scala.git
cd $PWD/jackson-module-scala
sbt compile
sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test
