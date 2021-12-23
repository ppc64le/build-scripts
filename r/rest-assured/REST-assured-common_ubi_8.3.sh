# ----------------------------------------------------------------------------
#
# Package       : REST-assured-common
# Version       : rest-assured-3.0.3 
# Source repo   : https://github.com/rest-assured/rest-assured.git
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Default tag REST-assured-common
if [ -z "$1" ]; then
  export VERSION="rest-assured-3.0.3"
else
  export VERSION="$1"
fi

#Variables
REPO=https://github.com/rest-assured/rest-assured.git
PACKAGE_VERSION=rest-assured-3.0.3

yum update -y
yum install -y git maven

# Cloning Repo
git clone $REPO
cd /rest-assured/rest-assured-common

git checkout ${VERSION}

# Build and test package
mvn clean install -DskipTests -B $PROFILES
mvn test
