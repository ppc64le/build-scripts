# ----------------------------------------------------------------------------
#
# Package       : Spring-security
# Version       : 5.1.3.RELEASE
# Source repo   : https://github.com/spring-projects/spring-security.git
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/spring-projects/spring-security.git

# Default tag antlr4-annotations
if [ -z "$1" ]; then
  export VERSION="5.1.3.RELEASE"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git

# install java
yum install -y java-11-openjdk-devel

# Cloning the repository from remote to local
git clone $REPO
cd spring-security/
git checkout -b ${VERSION}

# Build and test package
./gradlew build
./gradlew test
