# ----------------------------------------------------------------------------
#
# Package        : oam-kubernetes-runtime
# Version        : v0.3.2
# Source repo    : https://github.com/crossplane/oam-kubernetes-runtime
# Tested on      : RHEL 8.2
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eux

CWD=`pwd`

# Install dependencies
yum install -y make git wget gcc

# Download and install go
wget https://golang.org/dl/go1.14.13.linux-ppc64le.tar.gz
tar -xzf go1.14.13.linux-ppc64le.tar.gz
rm -rf go1.14.13.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and checkout submodules
mkdir -p $GOPATH/src/github.com/crossplane
cd $GOPATH/src/github.com/crossplane
git clone https://github.com/crossplane/oam-kubernetes-runtime.git
cd oam-kubernetes-runtime/
git checkout v0.3.2
make submodules

# Add power specific changes to "upbound/build" submodule
cp $CWD/upbound_build.patch build/
cd build
git apply upbound_build.patch
cd ..

# Apply power specific patches and trigger the build
sed -i 's/GOARCH=amd64/GOARCH=ppc64le/g' Dockerfile
sed -i 's/FROM oamdev\/gcr.io-distroless-static:nonroot/FROM gcr.io\/distroless\/static:nonroot-ppc64le/g' Dockerfile
make vendor vendor.check
make prepare-legacy-chart
make build.all

# Install unit test dependencies and run unit tests
mkdir $CWD/kubebuilder-tools
cd $CWD/kubebuilder-tools

wget https://github.com/kubernetes-sigs/kubebuilder/releases/download/v2.3.1/kubebuilder_2.3.1_linux_ppc64le.tar.gz
tar -xzf kubebuilder_2.3.1_linux_ppc64le.tar.gz
cp kubebuilder_2.3.1_linux_ppc64le/bin/kubebuilder .
rm -rf kubebuilder_2.3.1_linux_ppc64le.tar.gz kubebuilder_2.3.1_linux_ppc64le

wget https://dl.k8s.io/v1.19.0/kubernetes-server-linux-ppc64le.tar.gz
tar -xzf kubernetes-server-linux-ppc64le.tar.gz
cp kubernetes/server/bin/kube-apiserver .
rm -rf kubernetes-server-linux-ppc64le.tar.gz kubernetes

wget https://github.com/etcd-io/etcd/releases/download/v3.4.14/etcd-v3.4.14-linux-ppc64le.tar.gz
tar -xzf etcd-v3.4.14-linux-ppc64le.tar.gz
cp etcd-v3.4.14-linux-ppc64le/etcd .
rm -rf etcd-v3.4.14-linux-ppc64le.tar.gz etcd-v3.4.14-linux-ppc64le

export KUBEBUILDER_ASSETS=$CWD/kubebuilder-tools
cd $GOPATH/src/github.com/crossplane/oam-kubernetes-runtime
make test

# Install ginkgo and create kind cluster as dependencies for e2e tests and run tests
cd $GOPATH/src/
go get github.com/onsi/ginkgo/ginkgo
cd $CWD
curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-linux-ppc64le
chmod +x kind
export PATH=$PATH:`pwd`
kind create cluster --name=kind --image kbasheer/kindest-node:v1.18.0

cd $GOPATH/src/github.com/crossplane/oam-kubernetes-runtime
echo "e2e tests are flaky, you may experience failures (1 to 4 out of 11 specs may fail)"
make e2e USE_HELM3=true

echo "Build, image creation, unit/e2e test execution successful!"
