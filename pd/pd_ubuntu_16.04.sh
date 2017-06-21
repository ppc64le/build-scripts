# ----------------------------------------------------------------------------
#
# Package       : pd
# Version       : rc3
# Source repo   : https://github.com/pingcap/pd
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
export GOPATH=$HOME/pd
export PATH=$GOPATH/bin:$PATH

#Install dependency, golang
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

#Clone/get the source
cd $HOME
git clone https://github.com/pingcap/pd.git
cd pd
go get github.com/pingcap/pd

#Build and test
cd $GOPATH/src/github.com/pingcap/pd && make && \
        rm -rf vendor && ln -s _vendor/vendor vendor && \
        make check && go test $(go list ./...| grep -vE 'vendor|pd-server')
