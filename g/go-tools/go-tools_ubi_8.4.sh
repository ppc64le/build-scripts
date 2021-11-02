# ----------------------------------------------------------------------------
#
# Package       : go-tools
# Version       : v0.3.0-0.dev
# Source repo   : https://github.com/dominikh/go-tools
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -eu

VERSION="${1:-v0.3.0-0.dev}"

if [ -d "go-tools" ] ; then
  rm -rf go-tools
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git

# Download the repos
git clone https://github.com/dominikh/go-tools

# Build and Test go-tools
cd go-tools
git checkout $VERSION
export GO111MODULE="auto"
go test -v ./...
go get honnef.co/go/tools/cmd/staticcheck
go vet ./...
$(go env GOPATH)/bin/staticcheck ./...
