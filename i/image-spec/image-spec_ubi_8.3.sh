# -----------------------------------------------------------------------------
#
# Package       : opencontainers/image-spec
# Version       : v1.0.2
# Source repo   : https://github.com/microsoft/mimalloc.git
# Tested on     : UBI 8.3
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 
# ----------------------------------------------------------------------------

#!/bin/bash

set -e

PACKAGE_NAME=image-spec
PACKAGE_VERSION=${1:-v1.0.2}
PACKAGE_URL=https://github.com/opencontainers/image-spec.git

yum install -y git golang make
export PATH=$HOME/go/bin/:$PATH
#Clone the Repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
make install.tools
make lint
make test
