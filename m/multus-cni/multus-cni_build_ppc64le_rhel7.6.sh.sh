# ----------------------------------------------------------------------------
#
# Package       : multus-cni
# Version       : N/A
# Source repo   : https://github.com/openshift/multus-cni
# Tested on     : ppc64le_rhel7.6
# Script License: Apache License, Version 2 or later
# Maintainer's  : Rashmi Sakhalkar <srashmi@us.ibm.com>
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
yum install wget tar make gcc curl gettext-devel openssl-devel perl-devel zlib-devel dh-autoreconf curl-devel expat-devel gettext-devel asciidoc xmlto docbook2X -y

# Git > v2
cd /
wget https://github.com/git/git/archive/v2.22.0-rc2.tar.gz
tar -xf v2.22.0-rc2.tar.gz
cd git-2.22.0-rc2/
ln -s /usr/bin/db2x_docbook2texi /usr/bin/docbook2x-texi
make configure
./configure --prefix=/usr
make
make install

# Env var
export GOARCH=ppc64le
export GOOS=linux
export GO111MODULE=on
export PATH=$PATH:/root/go/bin

BUILD_HOME=`pwd`

# Go
cd /
wget https://dl.google.com/go/go1.12.15.linux-ppc64le.tar.gz
tar -xf go1.12.15.linux-ppc64le.tar.gz -C /usr/local/
export PATH=$PATH:/usr/local/go/bin

# Clone & build
cd $BUILD_HOME
git clone https://github.com/openshift/multus-cni.git
cd multus-cni

sed -i '85s/else {//' webhook/webhook.go
sed -i '86s/\t//' webhook/webhook.go
sed -i '87d' webhook/webhook.go

sed -i 's|"github.com/intel/multus-cni/types"|nettypes "github.com/k8snetworkplumbingwg/network-attachment-definition-client/pkg/apis/k8s.cni.cncf.io/v1"|' webhook/webhook.go
sed -i '34,$ s/types/nettypes/' webhook/webhook.go
sed -i 's/Metadata.Name/GetName()/' webhook/webhook.go
sed -i 's/Printf(logging.DebugLevel, /Verbosef(/g' webhook/webhook.go

sed -i 's|"github.com/intel/multus-cni/types"|nettypes "github.com/k8snetworkplumbingwg/network-attachment-definition-client/pkg/apis/k8s.cni.cncf.io/v1"|' webhook/webhook_test.go
sed -i '34,$ s/types/nettypes/' webhook/webhook_test.go
sed -i 's/Metadata/ObjectMeta/g' webhook/webhook_test.go

sed -i '25s/1/0/' build


go get -v github.com/mattn/goveralls
go get -v -u golang.org/x/lint/golint
golint ./... | grep -v vendor | grep -v ALL_CAPS | xargs -r false
go fmt ./...
go vet ./...
GOARCH="ppc64le" ./build

# Run container with --privileged flag if running test inside it.
env PATH=${PATH} ./test.sh
