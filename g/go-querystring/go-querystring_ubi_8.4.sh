# -----------------------------------------------------------------------------
#
# Package	: github.com/google/go-querystring
# Version	: v1.0.0
# Source repo	: https://github.com/google/go-querystring
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-querystring
PACKAGE_VERSION=${1:-v1.0.0}

yum install -y git golang

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone https://github.com/google/go-querystring
cd go-querystring
git checkout v$PACKAGE_VERSION
go build -v ./...
go test -v ./...
