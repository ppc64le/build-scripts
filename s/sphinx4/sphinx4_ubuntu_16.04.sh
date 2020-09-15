# ----------------------------------------------------------------------------
#
# Package	: sphinx4
# Version	: n/a
# Source repo	: https://github.com/cmusphinx/sphinx4
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
sudo apt-get install -y git wget unzip openjdk-8-jdk openjdk-8-jre

# Install gradle.
WDIR=`pwd`
wget https://services.gradle.org/distributions/gradle-2.10-bin.zip
unzip gradle-2.10-bin.zip

export PATH=$PATH:$WDIR/gradle-2.10/bin
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/cmusphinx/sphinx4
cd sphinx4
gradle build
gradle test
