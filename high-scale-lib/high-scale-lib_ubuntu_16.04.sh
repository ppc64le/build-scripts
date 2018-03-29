# ----------------------------------------------------------------------------
#
# Package	: high-scale-lib
# Version	: 1.1.4
# Source repo	: https://github.com/stephenc/high-scale-lib.git
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

sudo apt-get update -y
sudo apt-get -y install git wget maven openjdk-8-jdk openjdk-8-jre

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

git clone https://github.com/stephenc/high-scale-lib.git
cd high-scale-lib
mvn clean install
