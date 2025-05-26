#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : ingress-nginx
# Version       : controller-v1.2.0
# Source repo   : https://github.com/kubernetes/ingress-nginx.git
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

PACKAGE_NAME=ingress-nginx
PACKAGE_VERSION=${1:-controller-v1.2.0}
PACKAGE_URL=https://github.com/kubernetes/ingress-nginx.git
GO_VERSION=1.17
KINDEST_NODE_VERSION=v1.23.17
KIND_VERSION=v0.14.0
HELM_VERSION=v3.14.1
ARCH=ppc64le
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

echo fs.inotify.max_user_watches=655360 | tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | tee -a /etc/sysctl.conf

echo "PACKAGE VERSION "
echo $PACKAGE_VERSION
#Install dependencies
yum update -y
yum install -y --allowerasing git\
    wget \
    gcc  \
    make \
    git \
    zip unzip \
    curl \
    sudo \
    wget \
    rsync \
    tzdata \
	jq \
    net-tools

wdir=`pwd`

#Install Golang
cd $wdir
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH
go version
export PATH=$PATH:$HOME/go/bin

#Install centos and epel repos
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
 
#Install docker
yum install iptables-nft -y
yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"ipv6": true,
"fixed-cidr-v6": "2001:db8:1::/64",
"mtu": 1450
}
EOT
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Install Helm
curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz
tar -zxvf helm-${HELM_VERSION}-linux-${ARCH}.tar.gz
mv linux-${ARCH}/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version

#Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ppc64le
chmod +x ./kind
cp ./kind /usr/bin/
mv ./kind /usr/local/bin/kind

#Install kubectl
curl -LO https://dl.k8s.io/release/$KINDEST_NODE_VERSION/bin/linux/ppc64le/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl


#Build kindest/node image
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout $KINDEST_NODE_VERSION
kind build node-image .
docker tag kindest/node:latest kindest/node:$KINDEST_NODE_VERSION

#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply ../${PACKAGE_NAME}-${PACKAGE_VERSION}.patch

export GO111MODULE=on
export USER=$(whoami)
export ARCH=ppc64le
go mod download

cd images/nginx
make build
docker tag gcr.io/k8s-staging-ingress-nginx/nginx:0.0 local/ingress-nginx/nginx:base

cd ../test-runner/
make build
docker tag docker.io/local/e2e-test-runner:v1.0 local/e2e-test-runner:1.0

cd $wdir/${PACKAGE_NAME}
if ! make build ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make test ; then
        echo "------------------$PACKAGE_NAME:install_success_but_unit_test_fails---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_unit_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_&_unit_test_both_success-------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Unit_Test_Success"
fi


#Start a local Kubernetes cluster using kind, build and deploy the ingress controller
kind delete cluster --name ingress-nginx-dev
if ! make dev-env ; then
    echo "------------------$PACKAGE_NAME:dev env _fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Cluster Fails"
    exit 2
fi


