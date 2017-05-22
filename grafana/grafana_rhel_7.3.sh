# ----------------------------------------------------------------------------
#
# Package       : grafana
# Version       : v4.3.0-bet1
# Source repo   : https://github.com/grafana/grafana
# Tested on     : RHEL_7.3
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
yum update -y
yum install -y wget curl openssl-devel.ppc64le git tar bzip2 libwebp \
  libxslt fontconfig-devel libicu
yum groupinstall 'Development Tools' -y

#Install golang
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

#install phantomjs (ibmsoe binary)
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1-rhel7.2/phantomjs-2.1.1-linux-ppc64.tar.bz2 && \
tar -xf phantomjs-2.1.1-linux-ppc64.tar.bz2 && cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin

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
