# ----------------------------------------------------------------------------
#
# Package	: grizzly
# Version	: 2.4.3
# Source repo	: https://github.com/javaee/grizzly
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

sudo apt-get update 
sudo apt-get install -y build-essential default-jdk git maven

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

git clone https://github.com/javaee/grizzly
cd grizzly
mvn install
