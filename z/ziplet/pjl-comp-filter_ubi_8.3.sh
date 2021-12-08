# ----------------------------------------------------------------------------
#
# Package       : pjl-comp-filter
# Version       : ziplet-2.4.1
# Source repo   : https://github.com/ziplet/ziplet
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

#Variables
REPO=https://github.com/ziplet/ziplet 

# Default tag for pjl-comp-filter
if [ -z "$1" ]; then
  export VERSION="ziplet-2.4.1"
else
  export VERSION="$1"
fi

yum update -y
yum install -y git maven

# Cloning Repo
git clone $REPO
cd ./ziplet

git checkout $VERSION

# Build and test package
mvn clean install -DskipTests
mvn test