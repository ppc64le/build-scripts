# ----------------------------------------------------------------------------
#
# Package       : Jackson Jaxrs Json Providers
# Version       : 2.9.6
# Source repo   : https://github.com/FasterXML/jackson-jaxrs-providers.git
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
sudo apt-get install -y git maven openjdk-8-jdk

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

#Download source
git clone https://github.com/FasterXML/jackson-jaxrs-providers.git
cd jackson-jaxrs-providers
git checkout 2.9

# Build and Test
mvn clean package
mvn test
