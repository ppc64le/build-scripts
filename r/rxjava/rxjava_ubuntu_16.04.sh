# ----------------------------------------------------------------------------
#
# Package       : Reactivex rxJava
# Version       : 2.1.10
# Source repo   : https://github.com/ReactiveX/RxJava
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
sudo apt-get install -y build-essential gradle g++ \
    ant wget software-properties-common openjdk-8-jdk git

# Set ENV
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source and Build
git clone https://github.com/ReactiveX/RxJava
cd RxJava
./gradlew assemble
