# ----------------------------------------------------------------------------
#
# Package       : grafana
# Version       : v4.3.0-bet1
# Source repo   : https://github.com/grafana/grafana
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

#Install dependencies
apt-get update
apt-get install -y tar wget bzip2 libfontconfig curl


#Install golang
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH

#install phantomjs (ibmsoe binary)
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/


#Get the source and build Grafana
#References - http://docs.grafana.org/project/building_from_source/

cd $HOME
mkdir grafana
cd grafana
export GOPATH=`pwd`
go get github.com/grafana/grafana

cd $GOPATH/src/github.com/grafana/grafana
go run build.go setup
go run build.go build  

npm install -g yarn
yarn install --pure-lockfile
npm install node-sass
npm install

npm install -g grunt grunt-cli

grunt

go run build.go test
