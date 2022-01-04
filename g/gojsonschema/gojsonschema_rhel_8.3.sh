# -----------------------------------------------------------------------------
#
# Package       : gojsonschema
# Version       : v1.2.0
# Source repo   : https://github.com/xeipuuv/gojsonschema.git
# Tested on     : RHEL 8.3
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
# ------------------------------------------------------------------------------
set -e
PACKAGE_NAME=gojsonschema
PACKAGE_VERSION={1:-v1.2.0}
PACKAGE_URL=https://github.com/xeipuuv/gojsonschema.git

yum update -y && yum install -y git golang

#Add dependency
go get github.com/xeipuuv/gojsonschema
go get github.com/xeipuuv/gojsonpointer
go get github.com/xeipuuv/gojsonreference
go get github.com/stretchr/testify/assert

#clone the repo.
git clone $PACKAGE_URL
cd  $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#build  and test the package
go install
go test
