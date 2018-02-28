# ----------------------------------------------------------------------------
#
# Package       : Powermokito
# Version       : 1.7.4
# Source repo   : https://github.com/powermock/powermock.git
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# NOTE: Please make sure to set the ENV value for 'GH_USER' to your
#       github login. e.g. export GH_USER=user123
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo yum update -y
sudo yum install -y git java-1.8.0-openjdk

# Download source
git clone https://github.com/powermock/powermock.git
cd powermock
git checkout powermock-1.7.3

#Setting environment variables
export GH_USER=$GH_USER
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Build
./gradlew assemble -s -PcheckJava6Compatibility && \
./gradlew check
