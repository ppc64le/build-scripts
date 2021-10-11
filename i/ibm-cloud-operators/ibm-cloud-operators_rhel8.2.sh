# ----------------------------------------------------------------------------
#
# Package        : IBM cloud-operators
# Version        : v1.0.7
# Source repo    : https://github.com/IBM/cloud-operators.git
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

set -eu

CWD=`pwd`

PACKAGE_VERSION=v1.0.7

usage() {
    echo "Usage: $0 -k <IBMCLOUD_API_KEY> [-v <PACKAGE_VERSION>]"
    echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.0.7"
}

while getopts ":k:v:" opt; do
    case $opt in
        k) API_KEY="$OPTARG"
        ;;
        v) PACKAGE_VERSION="$OPTARG"
        ;;
        \?) usage
            exit 1
        ;;
    esac
done

if [ -z ${API_KEY+x} ]; then
    usage
    exit 1
fi

# Install dependencies
yum install -y make git wget gcc

# Download and install go
wget https://golang.org/dl/go1.15.11.linux-ppc64le.tar.gz
tar -xzf go1.15.11.linux-ppc64le.tar.gz
rm -rf go1.15.11.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and checkout submodules
mkdir -p $GOPATH/src/github.com/IBM
cd $GOPATH/src/github.com/IBM
git clone https://github.com/IBM/cloud-operators.git
cd cloud-operators
git checkout $PACKAGE_VERSION
sed -i 's/RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager main.go/RUN CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le GO111MODULE=on go build -a -o manager main.go/g' Dockerfile
sed -i 's/FROM gcr.io\/distroless\/static:nonroot/FROM gcr.io\/distroless\/static:nonroot-ppc64le/g' Dockerfile
git apply $CWD/kustomize_build.patch
sed -i 's/gcr.io\/kubebuilder\/kube-rbac-proxy:v0.5.0/carlosedp\/kube-rbac-proxy:v0.5.0/g' config/default/manager_auth_proxy_patch.yaml
sed -i 's/assets=$(fetch_assets "${file_urls\[@\]}")/assets="$(pwd)\/out\/"/g' hack/configure-operator.sh

# Build and execute unit, e2e tests
make controller-gen
make kustomize
make -e RELEASE_VERSION=${PACKAGE_VERSION:1} release-prep
make -e RELEASE_VERSION=${PACKAGE_VERSION:1} docker-build

# Enable the following for test execution iff:
# - you have necessary permissions to create/edit/alias following IBM cloud services:
#    language-translator, cloud-object-storage, messagehub
# - you are assigned an IAM Editor role or higher
: '
# resolve kubebuilder and related dependencies for test execution { TEST_DEPS
mkdir -p cache/kubebuilder_2.3.1/bin/
mkdir $CWD/kubebuilder
cd $CWD/kubebuilder
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

mv * $GOPATH/src/github.com/IBM/cloud-operators/cache/kubebuilder_2.3.1/bin/
# } TEST_DEPS
cd $GOPATH/src/github.com/IBM/cloud-operators

export BLUEMIX_RESOURCE_GROUP=Default
export BLUEMIX_ORG=unused
export BLUEMIX_SPACE=unused
export BLUEMIX_REGION=us-south
export BLUEMIX_API_KEY=$API_KEY

make test
'

echo "Build, image creation, test execution successful!"
