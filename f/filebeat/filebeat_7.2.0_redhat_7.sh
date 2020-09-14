# ----------------------------------------------------------------------------
#
# Package       : filebeat
# Version       : 7.2.0
# Source repo   : https://github.com/elastic/beats.git
# Tested on     : RHEL 7.5
# Script License: Apache License Version 2.0
# Maintainer    : Edmond Chan <ckchan@hk1.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# install dependencies
yum install golang make git

mkdir go
export GOPATH=~/go
mkdir -p ${GOPATH}/src/github.com/elastic
cd ${GOPATH}/src/github.com/elastic
git clone https://github.com/elastic/beats.git
cd $GOPATH/src/github.com/elastic/beats/filebeat
git checkout v7.2.0
make
