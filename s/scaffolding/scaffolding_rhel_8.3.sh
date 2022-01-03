# ---------------------------------------------------------------------
#
# Package       : scaffolding
# Version       : 0.52.1
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/prometheus-operator/prometheus-operator.git
PACKAGE_VERSION=0.52.1

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 10.9.1, not all versions are supported."

PACKAGE_VERSION="v${1:-$PACKAGE_VERSION}"

#install dependencies
yum update -y
yum install -y git go gcc gcc-c++ make xz.ppc64le

git clone $REPO
cd prometheus-operator/
git checkout $PACKAGE_VERSION
#build
make 

#unit test
#Few test cases are failing on x86 and power VM as well
make test-unit
