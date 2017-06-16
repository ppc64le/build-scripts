# ----------------------------------------------------------------------------
#
# Package	: scala-guice
# Version	: 4.1.0
# Source repo	: https://github.com/codingwell/scala-guice.git
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
sudo rm -rf /etc/apt/sources.list.d/sbt.list
sudo touch /etc/apt/sources.list.d/sbt.list
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get update -y

sudo apt-get install -y build-essential dirmngr apt-transport-https \
    openjdk-8-jdk openjdk-8-jre git sbt

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/codingwell/scala-guice.git
cd scala-guice
git checkout -qf 52fb146e73b8be0075f994ace8a6af6928ff00ec
javac -J-Xmx32m -version
sbt compile
sbt test
