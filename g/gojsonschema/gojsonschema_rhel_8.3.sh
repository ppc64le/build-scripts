# -----------------------------------------------------------------------------
#
# Package       : xeipuuv/gojsonschema
# Version       : v1.2.0
# Source repo   : https://github.com/xeipuuv/gojsonschema.git
# Tested on     : UBI 8
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
yum update -y
yum install -y git golang

VERSION=${1:-v1.2.0}
#Add dependency
go get github.com/xeipuuv/gojsonschema
go get github.com/xeipuuv/gojsonpointer
go get github.com/xeipuuv/gojsonreference
go get github.com/stretchr/testify/assert

#clone the repo.
git clone https://github.com/xeipuuv/gojsonschema.git
cd  gojsonschema/
git checkout $VERSION

#build  and test the package
go install
go test
