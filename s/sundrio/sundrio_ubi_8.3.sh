# ----------------------------------------------------------------------------
#
# Package       : sundrio
# Version       : 0.21.0
# Source repo   : https://github.com/sundrio/sundrio
# Tested on     : UBI 8.3
# Script License: Apache License 2.0
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Tested versions: 0.21.0, 0.18.0
#!/bin/bash

# Default tag sundrio
if [ -z "$1" ]; then
  export VERSION="0.21.0"
else
  export VERSION="$1"
fi

#Variables
REPO=https://github.com/sundrio/sundrio.git

#Install required dependencies
yum update -y
yum install -y git maven 

#Cloning Repo
git clone $REPO
cd sundrio/
git checkout ${VERSION}

#Build and test package
mvn package -DskipTests
mvn test