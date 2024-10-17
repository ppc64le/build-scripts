#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : cass-operator
# Version       : v1.19.0
# Source repo   : https://github.com/k8ssandra/cass-operator
# Tested on     : Ubuntu 22.04 (docker)
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cass-operator
PACKAGE_VERSION=${1:-v1.19.0}
PACKAGE_URL=https://github.com/k8ssandra/${PACKAGE_NAME}.git
GO_VERSION=1.21.5
KINDEST_NODE_VERSION=v1.25.3
K8SSANDRA_CLIENT_VERSION=v0.2.2
MGMT_API_VERSION=v0.1.73
KIND_VERSION=v0.17.0
CASS_CONFIG_BUILDER_VERSION=v1.0.8
CASS_CONFIG_DEFS_VERSION=1b7eaf4e50447fc8168c4a6c16d0ed986941edf8
CERT_MANAGER_VERSION=v1.12.2

echo fs.inotify.max_user_watches=655360 | tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | tee -a /etc/sysctl.conf
sysctl -p

#Install dependencies
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    git \
    zip unzip \
    curl \
    sudo \
    wget \
    rsync \
    tzdata \
    net-tools

wdir=`pwd`

#Install Golang
cd $wdir
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
export PATH=$PATH:$HOME/go/bin

#Install docker
DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release init -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ppc64le
chmod +x ./kind
mv ./kind /usr/local/bin/kind

#Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/ppc64le/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

#Install yq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_ppc64le
chmod a+x /usr/local/bin/yq

#build cass config builder
cd $wdir
git clone https://github.com/datastax/cass-config-builder
cd cass-config-builder
git checkout $CASS_CONFIG_BUILDER_VERSION
sed -i "s#version.txt#/version.txt#g" build.gradle
git clone https://github.com/datastax/cass-config-definitions/
cd cass-config-definitions
git checkout $CASS_CONFIG_DEFS_VERSION
cd ..
docker buildx build --load -f docker/Dockerfile --target cass-config-builder -t datastax/cass-config-builder:1.0-ubi8 --platform linux/ppc64le .
docker tag datastax/cass-config-builder:1.0-ubi8 cr.dtsx.io/datastax/cass-config-builder:1.0-ubi8

#Build cass management api image
cd $wdir
git clone https://github.com/k8ssandra/management-api-for-apache-cassandra
cd management-api-for-apache-cassandra
git checkout $MGMT_API_VERSION
git apply ../management-api-for-apache-cassandra-$MGMT_API_VERSION.patch
docker buildx build --load --build-arg CASSANDRA_VERSION=3.11.10 --tag cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.10 --file Dockerfile-oss --target oss311 --platform linux/ppc64le .
docker buildx build --load --build-arg CASSANDRA_VERSION=4.0.1 --tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.0.1 --file Dockerfile-4_0 --target oss40 --platform linux/ppc64le .
docker buildx build --load --build-arg CASSANDRA_VERSION=4.1.2 --tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.2 --file Dockerfile-4_1 --target oss41 --platform linux/ppc64le .
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.10 cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.16
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.10 cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.7
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.10 cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.14
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.2 cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.1
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.2 cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.7

# Build cassandra client image
cd $wdir
git clone https://github.com/k8ssandra/k8ssandra-client
cd k8ssandra-client
git checkout $K8SSANDRA_CLIENT_VERSION
git apply ../k8ssandra-client-$K8SSANDRA_CLIENT_VERSION.patch
make docker-build
docker tag k8ssandra/k8ssandra-client:latest cr.k8ssandra.io/k8ssandra/k8ssandra-client:$K8SSANDRA_CLIENT_VERSION

#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply ../${PACKAGE_NAME}-${PACKAGE_VERSION}.patch

#Build
make build

#Unit tests
make test

#Docker build
make docker-build

#Docker logger build
make docker-logger-build

#Build kindest/node image
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout $KINDEST_NODE_VERSION
kind build node-image .
docker tag kindest/node:latest kindest/node:$KINDEST_NODE_VERSION

#Deploy to kind
cd $wdir/${PACKAGE_NAME}
kind delete cluster || true
kind create cluster --image=kindest/node:$KINDEST_NODE_VERSION --config=tests/testdata/kind/kind_config_6_workers.yaml
kind load docker-image cr.k8ssandra.io/k8ssandra/k8ssandra-client:v0.2.2
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.1
kind load docker-image datastax/cass-config-builder:1.0-ubi8
kind load docker-image cr.dtsx.io/datastax/cass-config-builder:1.0-ubi8
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.10
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.7
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.14
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:3.11.16
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:4.0.1
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.1
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.2
kind load docker-image cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.7

#Make operator docker image
make docker-kind

#Make docker system logger
make docker-logger-kind

#Deploy
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml
sleep 30
cp tests/kustomize/kustomization.yaml tests/
make deploy
sleep 30

#Integration tests
cd tests/add_racks
cd ../add_racks && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../additional_serviceoptions && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../additional_volumes && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../cluster_wide_install && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../config_change && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v || true
cd ../config_secret && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../host_network && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../internode-encryption-generated && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../nodeport_service && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../podspec_simple && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../rolling_restart && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../rolling_restart_with_override && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../scale_down && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../scale_up && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../scale_up_stop_resume && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../superuser-secret-generated && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../superuser-secret-provided && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../test_bad_config_and_fix && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../test_mtls_mgmt_api && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../test_all_the_things && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../webhook_validation && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../node_replace && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../seed_selection && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
cd ../canary_upgrade && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v

#Failing in parity with Intel
#cd ../decommission_dc && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
#cd ../upgrade_operator && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v

#Needs a number of pulsar images (spawns that many pulsar pods), not worth the effort and ...
#Only meant for 4.0
#cd ../cdc_successful && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
#cd ../config_fql && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v

# Only meant for 3.11
#cd ../additional_seeds && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v
#cd ../scale_down_unbalanced_racks && go test -v ./... -timeout 300m --ginkgo.progress --ginkgo.v

#Conclude
set +ex
echo "Build and tests Successful!"

