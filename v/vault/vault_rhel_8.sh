# ----------------------------------------------------------------------------
#
# Package       : Vault
# Version       : 1.5.3
# Source repo   : https://github.com/RediSearch/RediSearch.git
# Tested on     : RHEL 7.8
# Script License: Apache License, Version 2 or later
# Maintainer    : Kandarpa Malipeddi <kandarpa.malipeddi.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

VAULT_VERSION=v1.5.3

yum install -y openssl sudo make git gcc wget

wget https://golang.org/dl/go1.14.7.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go1.14.7.linux-ppc64le.tar.gz
rm -rf go1.14.7.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH

mkdir -p /go/src/github.com/hashicorp

export GOPATH=/go
export PATH=$PATH:$GOPATH/bin

cd /go/src/github.com/hashicorp
git clone https://github.com/hashicorp/vault
cd vault
git checkout ${VAULT_VERSION}
make bootstrap && make

####################################################
# Vault have dependency on multiple docker images.
# Most of them not available for PPC64LE.
# Currently we are working on it.
# Once done with that, will enable the tests.
####################################################

#make test
