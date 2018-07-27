# ----------------------------------------------------------------------------
#
# Package	: gson
# Version	: 2.8.5
# Source repo	: https://github.com/google/gson
# Tested on	: ubuntu_18.04
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
sudo apt-get install -y git openjdk-8-jdk openjdk-8-jre maven
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

git clone https://github.com/google/gson
cd gson
mvn install
mvn test
