# ----------------------------------------------------------------------------
#
# Package       : Reactivex rxScala
# Version       : 0.26.5
# Source repo   : https://github.com/ReactiveX/RxScala
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
sudo apt-get install -y apt-transport-https
sudo rm -rf /etc/apt/sources.list.d/sbt.list
sudo touch /etc/apt/sources.list.d/sbt.list
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get update -y
sudo apt-get install -y build-essential dirmngr bc git openjdk-8-jdk sbt

# Set Environments
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source and Build
git clone https://github.com/ReactiveX/RxScala
cd RxScala
sbt compile && sbt test
