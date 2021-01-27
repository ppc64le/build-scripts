# ----------------------------------------------------------------------------
#
# Package        : crossplane
# Version        : v1.0.0
# Source repo    : https://github.com/crossplane/crossplane
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

# Build crossplane/oam-kubernetes-runtime:v0.2.2 image as dependency for e2e
# since the image on docker hub is not multiarch
cd $CWD
git clone https://github.com/crossplane/oam-kubernetes-runtime.git
cd oam-kubernetes-runtime/
git checkout v0.2.2
sed -i 's/GOARCH=amd64/GOARCH=ppc64le/g' Dockerfile
sed -i 's/FROM oamdev\/gcr.io-distroless-static:nonroot/FROM gcr.io\/distroless\/static:nonroot-ppc64le/g' Dockerfile
docker build -t crossplane/oam-kubernetes-runtime:v0.2.2 .

# Download the oam-kubernetes-runtime-0.2.2 chart and update image pull policy
cd $CWD
mkdir cscharts
cd cscharts
wget https://charts.crossplane.io/alpha/oam-kubernetes-runtime-0.2.2.tgz
tar -xzf oam-kubernetes-runtime-0.2.2.tgz
cd oam-kubernetes-runtime
sed -i 's/pullPolicy: Always/pullPolicy: IfNotPresent/g' values.yaml.tmpl
sed -i 's/pullPolicy: Always/pullPolicy: IfNotPresent/g' values.yaml

# Clone the repo and checkout submodules
mkdir -p $GOPATH/src/github.com/crossplane
cd $GOPATH/src/github.com/crossplane
git clone https://github.com/crossplane/crossplane.git
cd crossplane/
git checkout v1.0.0
export USE_HELM3=true
export PLATFORMS=linux_ppc64le
make submodules

# Add power specific changes to "upbound/build" submodule
sed -i -n '/$(error build only supported on amd64 host currently)/{N;s/.*//;x;d;};x;p;${x;p;}' build/makelib/common.mk
sed -i -e '/OSBASEIMAGE = arm64v8\/$(OSBASE)/a \
else ifeq ($(ARCH),ppc64le)\
OSBASEIMAGE = registry.access.redhat.com/ubi8:8.2' build/makelib/image.mk
# Fix the following helm init related errors:
# 1. You might need to run `helm init` (or `helm init --client-only` if tiller is already installed)
# 2. error initializing: Looks like "https://kubernetes-charts.storage.googleapis.com" is not a valid chart repository
#    or cannot be reached: Failed to fetch https://kubernetes-charts.storage.googleapis.com/index.yaml : 403 Forbidden
sed -i 's/@$(HELM) init -c/@$(HELM) init --stable-repo-url=https:\/\/charts.helm.sh\/stable --client-only/g' build/makelib/helm.mk
# Update the dockerfile to adhere to UBI base
sed -i 's/RUN apk --no-cache add ca-certificates bash/RUN yum install -y ca-certificates bash/g' cluster/images/crossplane/Dockerfile
# The following patches make sure to use locally built oam-kubernetes-runtime image for e2e tests
sed -i 's@https://charts.crossplane.io/alpha@file://'"${CWD}"'/cscharts/oam-kubernetes-runtime@g' cluster/charts/crossplane/requirements.yaml
sed -i -e '/"\${KIND}" load docker-image "\${CROSSPLANE_IMAGE}" --name="\${K8S_CLUSTER}"/a\
"\${KIND}" load docker-image "crossplane/oam-kubernetes-runtime:v0.2.2" --name="\${K8S_CLUSTER}"\n' cluster/local/integration_tests.sh
# Make ppc64le based kindest-node available for e2e tests
sed -i 's/"${KIND}" create cluster --name="${K8S_CLUSTER}"/"${KIND}" create cluster --name="${K8S_CLUSTER}" --image kbasheer\/kindest-node:v1.18.0/g' cluster/local/integration_tests.sh

# Build and execute unit, e2e tests 
make vendor vendor.check
make build.all
make test
make e2e

echo "Build, image creation, unit/e2e test execution successful!"
