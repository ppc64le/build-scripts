# ----------------------------------------------------------------------------
#
# Package       : grpcurl
# Version       : v1.8.2
# Source repo   : https://github.com/fullstorydev/grpcurl
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
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
REPO=https://github.com/fullstorydev/grpcurl
PACKAGE_VERSION=v1.8.2

yum install -y golang git

git clone $REPO
cd grpcurl
git checkout $PACKAGE_VERSION 
cd cmd/grpcurl/
go build