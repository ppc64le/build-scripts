# -----------------------------------------------------------------------------
#
# Package	: sketches-go
# Version	: v1.2.1
# Source repo	: https://github.com/DataDog/sketches-go
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar <Sapana.Khemkar@ibm.com>
# Languge	: go
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=sketches-go
PACKAGE_URL=github.com/DataDog/sketches-go
PACKAGE_VERSION=v1.2.1

set -e

yum install -y git python3 wget tar gcc-c++

#install go
rm -rf /bin/go
wget https://go.dev/dl/go1.17.5.linux-ppc64le.tar.gz
tar -C /bin -xzf go1.17.5.linux-ppc64le.tar.gz  
rm -f go1.17.5.linux-ppc64le.tar.gz 

mkdir -p /home/tester/go

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

cd /home/tester/go
go get -u $PACKAGE_URL@$PACKAGE_VERSION

cd pkg/mod/github.com/\!data\!dog/sketches-go@v1.2.1
go mod tidy
go test -v ./...

exit 0
