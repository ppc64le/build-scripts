# ----------------------------------------------------------------------------
#
# Package       : zap
# Version       : v1.19.1
# Source repo   : https://github.com/uber-go/zap
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

VERSION="${1:-v1.19.1}"

if [ -d "zap" ] ; then
  rm -rf zap
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git make

# Download the repos
git clone https://github.com/uber-go/zap

# Build and Test zap
cd zap
git checkout $VERSION
export GO111MODULE="auto"
go mod download
make lint
make cover
make bench
