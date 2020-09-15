# ----------------------------------------------------------------------------
#
# Package       : filebeat
# Version       : 6.5.4
# Source repo   : https://github.com/elastic/beats.git
# Tested on     : ubuntu_18.04
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
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
apt-get -y update && apt-get install -y golang make git

mkdir go
export GOPATH=~/go
mkdir -p ${GOPATH}/src/github.com/elastic
cd ${GOPATH}/src/github.com/elastic
git clone https://github.com/elastic/beats.git
cd $GOPATH/src/github.com/elastic/beats/filebeat
git checkout v6.5.4
make
