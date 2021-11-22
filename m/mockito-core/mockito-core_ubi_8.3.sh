# ----------------------------------------------------------------------------
#
# Package       : mockito-core
# Version       : 3.4.0
# Source repo   : https://github.com/mockito/mockito
# Tested on     : UBI: 8.3
# Script License: MIT License
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
REPO=https://github.com/mockito/mockito.git
VERSION=v3.4.0
DIR=mockito

echo "Usage: $0 [-v <VERSION>]"
echo "       VERSION is an optional paramater whose default value is v3.4.0"

VERSION="${1:-$VERSION}"

# install tools and dependent packages
yum update -y
yum install -y git


# install java
yum -y install java-1.8.0-openjdk-devel

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

#Build without tests
./gradlew build

#Run tests
./gradlew test