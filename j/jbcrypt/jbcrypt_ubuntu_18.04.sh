# ----------------------------------------------------------------------------
#
# Package	: jBCrypt
# Version	: 0.4
# Source repo	: https://github.com/jeremyh/jBCrypt
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
sudo apt-get install -y git maven openjdk-8-jdk openjdk-8-jre
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

# Clone and build source.
git clone https://github.com/jeremyh/jBCrypt
cd jBCrypt
mvn clean install
mvn test
