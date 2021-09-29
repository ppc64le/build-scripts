# ---------------------------------------------------------------------
#
# Package       : fontawesome-free
# Version       : 5.1.0
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
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
PACKAGE_VERSION=5.1.0

#Install
yum install -y nodejs
npm install --save @fortawesome/fontawesome-free@$PACKAGE_VERSION

echo "Complete!"
