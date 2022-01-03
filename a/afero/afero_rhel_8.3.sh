# -----------------------------------------------------------------------------
#
# Package       : spf13/afero
# Version       : 588a75e
# Source repo   : https://github.com/spf13/afero.git
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

VERSION=${1:-588a75e}

#Add dependency
go get github.com/spf13/afero

#clone the repo.
git clone https://github.com/spf13/afero.git
cd  afero/
git checkout $VERSION

#build  and test the package
go install
go test
