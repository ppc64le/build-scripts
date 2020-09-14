# ----------------------------------------------------------------------------
#
# Package       : kabanero-command-line
# Version       : vlatest
# Source repo   : https://github.com/kabanero-io/kabanero-command-line
# Tested on     : rhel7.6 & ubi8
# Script License: Apache License, Version 2 or later
# Maintainer's  : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#                 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e
yum update -y

#Install Dependencies
yum install -y git gcc

#Install Go
curl -o /tmp/go.tar.gz https://dl.google.com/go/go1.13.8.linux-ppc64le.tar.gz
tar xf /tmp/go.tar.gz -C /usr/local/
export GOPATH="$HOME/go"
export GOROOT="/usr/local/go"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"

#Clone
export CLI_SRC="$GOPATH/src/github.com/kabanero-io/kabanero-command-line"
mkdir -p $CLI_SRC
git clone https://github.com/kabanero-io/kabanero-command-line.git $CLI_SRC 

#Build
cd $CLI_SRC
GOBIN=/usr/local/bin/ go install
kabanero-command-line version
