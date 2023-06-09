# ----------------------------------------------------------------------------
#
# Package       : go-tools
# Version       : v0.0.1-2019.2.3,v0.0.1-2020.1.3
# Source repo   : https://github.com/dominikh/go-tools
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Mukati <Amit.Mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_NAME="go-tools"
PACKAGE_VERSION=${1:-"v0.0.1-2019.2.3"}
PACKAGE_URL="https://github.com/dominikh/go-tools"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


export GO_VERSION=${GO_VERSION:-"1.11"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

# Dependency installation
yum install -y git wget gcc gcc-c++

# Download the repos
#git clone https://github.com/dominikh/go-tools
git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION" || exit 1
export GO111MODULE=on

# Build 
go build -v ./...

#test
go test -v ./...
go get honnef.co/go/tools/cmd/staticcheck
go vet ./...
cd staticcheck
go test

