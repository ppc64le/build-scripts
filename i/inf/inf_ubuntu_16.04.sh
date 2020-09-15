# ----------------------------------------------------------------------------
#
# Package	: inf
# Version	: 0.9.0
# Source repo	: https://github.com/go-inf/inf.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y cpp libc6-dev autoconf automake bison flex libtool \
    ecj make texinfo libgmp10 libmpfr4 libmpfr-dev libmpc3 libmpc-dev zip \
    unzip antlr subversion zlib1g zlib1g-dev subversion build-essential git \
    gccgo golang-go

workdir=`pwd`
git clone https://github.com/go-inf/inf.git
cd inf
mkdir go

export GOPATH=$workdir/inf/go
export PATH=/usr/lib/go:/usr/bin/go:$PATH
go get gopkg.in/inf.v0
go test -v ./...
