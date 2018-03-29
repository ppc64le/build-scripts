# ----------------------------------------------------------------------------
#
# Package       : JSR353 (JSON processing)
# Version       : 2.9.5
# Source repo   : https://github.com/FasterXML/jackson-datatype-jsr353
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

#Download source and Build
git clone https://github.com/FasterXML/jackson-datatype-jsr353
cd jackson-datatype-jsr353
mvn clean package
mvn test
