#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : keda
# Version       : v2.16.1
# Source repo   : https://github.com/kedacore/keda.git
# Tested on     : UBI 9.3 (docker)
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar<Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -euo pipefail

PACKAGE_NAME=keda
PACKAGE_VERSION=${1:-v2.16.1}
PACKAGE_URL=https://github.com/kedacore/keda.git
GO_VERSION=1.23.4
KUBECTL_VERSION=v1.31.0
KIND_VERSION="v0.17.0"
ARCH="ppc64le"
HELM_VERSION="v3.14.3"
CLUSTER_NAME="keda-test"
CHARTS_VERSION="${PACKAGE_VERSION#v}"
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
wdir=`pwd`

# Install dependencies
yum install -y gcc-c++ make wget git yum-utils iptables-nft rsync

# Install Go
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -f go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH
export PATH=$PATH:$HOME/go/bin
go version

# Setup CentOS repositories
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum install protobuf protobuf-devel protobuf-c protobuf-c-devel -y
export PROTOC=/usr/local/bin/
export PATH=$PROTOC:$PATH
export PROTOBUF_C=/protobuf-c/protobuf-c
export PATH=$PROTOBUF_C:$PATH
protoc --version

# Install Docker
yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "mtu": 1450
}
EOF
dockerd > /dev/null 2>&1 &
sleep 10
docker run hello-world

# Install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/ppc64le/kubectl"
chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${ARCH}
chmod +x ./kind && mv ./kind /usr/local/bin/kind
kind version

#Build kind node image
mkdir -p $HOME/go/src/k8s.io
cd $HOME/go/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout $KUBECTL_VERSION
kind build node-image .
docker tag kindest/node:latest kindest/node:$KUBECTL_VERSION

# Create kind cluster
cd $wdir
kind delete cluster --name $CLUSTER_NAME
kind create cluster --name $CLUSTER_NAME --image kindest/node:$KUBECTL_VERSION

# Install Helm
curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz
tar -zxvf helm-${HELM_VERSION}-linux-${ARCH}.tar.gz
mv linux-${ARCH}/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version

# Add KEDA Helm repository (must be before 'helm pull')
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
# Pull KEDA chart and prepare
mkdir -p $wdir/helm
cd $wdir/helm 
helm pull kedacore/keda --version $CHARTS_VERSION --untar
cp $wdir/values-$PACKAGE_VERSION.yaml ./keda/values.yaml
# Install KEDA
helm install keda ./keda --namespace keda --create-namespace
kubectl get pods -n keda

cd $wdir
git clone https://github.com/kedacore/test-tools.git/
cd test-tools &&  git checkout 327a1a529bf009ac8ffa6a2eb977a78346320577
git apply ../test-tools-327a1a5.patch
make  build-keda-tools
docker tag ghcr.io/kedacore/keda-tools:${GO_VERSION} keda-tools:${GO_VERSION}
  
# Clone and run KEDA tests
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply ../${PACKAGE_NAME}-${PACKAGE_VERSION}.patch

#build and test the package
if ! make build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

#Skipping tests whose failures are in parity with x86
if ! make test; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Build_and_Test_Success"
fi

#Build keda and dependent images for e2e testing
make docker-build

cd $wdir/test-tools/e2e/images/prometheus/
docker build -t ghcr.io/kedacore/tests-prometheus:latest .

cd ../hey/
docker build -t ghcr.io/kedacore/tests-hey .

docker pull prom/prometheus:v2.47.1
docker pull jimmidyson/configmap-reload:v0.3.0

# Load all required images into kind cluster
kind load docker-image prom/prometheus:v2.47.1 --name $CLUSTER_NAME
kind load docker-image jimmidyson/configmap-reload:v0.3.0 --name $CLUSTER_NAME
kind load docker-image ghcr.io/kedacore/tests-prometheus:latest --name $CLUSTER_NAME
kind load docker-image ghcr.io/kedacore/tests-hey:latest --name $CLUSTER_NAME
kind load docker-image ghcr.io/kedacore/keda:$PACKAGE_VERSION --name $CLUSTER_NAME
kind load docker-image ghcr.io/kedacore/keda-metrics-apiserver:$PACKAGE_VERSION --name $CLUSTER_NAME
kind load docker-image ghcr.io/kedacore/keda-admission-webhooks:$PACKAGE_VERSION --name $CLUSTER_NAME

# Set DockerHub secret if rate limited (update with your credentials)
# kubectl create secret docker-registry dockerhub-secret --docker-server=docker.io --docker-username=YOUR_USER --docker-password=YOUR_PASS --docker-email=you@example.com
# kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "dockerhub-secret"}]}'

echo "✅ All components installed and configured successfully."

cd $wdir/keda/tests/
go test -v -tags e2e ./scalers/prometheus/prometheus_test.go

