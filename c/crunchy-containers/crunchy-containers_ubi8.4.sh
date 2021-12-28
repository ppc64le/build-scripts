# ----------------------------------------------------------------------------
#
# Package        : crunchy-containers
# Version        : 4.5.1/4.7.0
# Source repo    : https://github.com/CrunchyData/crunchy-containers
# Tested on      : UBI 8.4
# Script License : Apache License, Version 2 or later
# Maintainer     : Sapana Khemkar <spana.khemkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# verified versions are 4.5.1, 4.7.0, 5.0.4
#!/bin/bash
PACKAGE_URL=https://github.com/CrunchyData/crunchy-containers
PACKAGE_NAME=crunchy-containers
PACKAGE_VERSION=4.5.1
GO_VERSION="go1.15"

set -e

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 4.5.1, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}" 
cd  /
#install dependencies
yum install -y wget git tar gcc-c++&& 

curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
&& dnf install -y epel-release-latest-8.noarch.rpm \
&& rm -f epel-release-latest-8.noarch.rpm

#install go
rm -rf /bin/go
wget https://golang.org/dl/$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  && \
rm -f $GO_VERSION.linux-ppc64le.tar.gz && \

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src/github.com/crunchydata
cd $GOPATH/src/github.com/crunchydata
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout v$PACKAGE_VERSION

go mod tidy
go build ./...
go test ./...

exit 0
