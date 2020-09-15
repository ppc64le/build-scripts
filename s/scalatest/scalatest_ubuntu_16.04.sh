# ----------------------------------------------------------------------------
#
# Package	: scalatest
# Version	: 3.0.3
# Source repo	: https://github.com/scalatest/scalatest
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo rm -rf /etc/apt/sources.list.d/sbt.list
sudo touch /etc/apt/sources.list.d/sbt.list
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get install -y apt-transport-https
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk openjdk-8-jre dirmngr sbt python g++ \
    build-essential make
sudo apt-get install -y ca-certificates-java
sudo update-ca-certificates -f

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
export SBT_OPTS="-server -Xms512M -Xmx3000M -Xss1M  -XX:+UseConcMarkSweepGC -XX:NewRatio=8"
#export JAVA_OPTS="-Xms512M -Xmx4096M -XX:MaxPermSize=1024M"
export _JAVA_OPTIONS="-Xmx4096m"

# Clone and build source code.
git clone https://github.com/scalatest/scalatest
cd scalatest
sbt compile
sbt test
