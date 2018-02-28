# ----------------------------------------------------------------------------
#
# Package	: apache directory-server
# Version	: 2.0.0-M24
# Source repo	: https://github.com/apache/directory-server
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite<smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WDIR=`pwd`
sudo apt-get update -y
sudo apt-get install -y build-essential default-jdk git maven

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

cd $WDIR
git clone https://github.com/apache/directory-server
cd $WDIR/directory-server
git checkout 1a6205e780ec66e2a6094b0f65f6cab62d4b8d0b
sudo mvn clean install
