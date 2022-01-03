# ----------------------------------------------------------------------------
#
# Package       : automaxprocs
# Version       : v1.4.0
# Source repo   : https://github.com/uber-go/automaxprocs
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

VERSION="${1:-v1.4.0}"

if [ -d "automaxprocs" ] ; then
  rm -rf automaxprocs
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git make

# Download the repos
git clone https://github.com/uber-go/automaxprocs

# Build and Test automaxprocs
cd automaxprocs
git checkout $VERSION
export GO111MODULE="auto"
go vet ./...
make lint
make test
make cover
