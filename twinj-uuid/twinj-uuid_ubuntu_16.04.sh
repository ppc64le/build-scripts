# ----------------------------------------------------------------------------
#
# Package       : Twinj-UUID
# Version       : 1.0.0
# Source repo   : https://github.com/twinj/uuid.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update
sudo apt-get install -y gccgo golang-go git

# Download source
sudo mkdir -p /usr/lib/go/src/github.com/twinj 
cd /usr/lib/go/src/github.com/twinj
sudo git clone https://github.com/twinj/uuid.git
sudo GOPATH=/usr/lib/go go get github.com/stretchr/testify

# Run tests
cd uuid
GOPATH=/usr/lib/go go test -v -short
