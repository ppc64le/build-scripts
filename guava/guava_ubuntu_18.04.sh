# ----------------------------------------------------------------------------
#
# Package	: guava
# Version	: 25.1
# Source repo	: https://github.com/google/guava
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git openjdk-8-jdk openjdk-8-jre maven
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

# Clone and build source.
git clone https://github.com/google/guava
cd guava
mvn install
mvn test
