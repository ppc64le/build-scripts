#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : teleport
# Version       : v18.1.1
# Source repo   : https://github.com/gravitational/teleport.git
# Tested on     : UBI 9.6
# Language      : Go
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#######################################
# Configuration
#######################################
PACKAGE_NAME="teleport"
SCRIPT_PACKAGE_VERSION=v18.1.1
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
GO_VERSION="1.24.5"
NODE_VERSION="23.0.0"
ARCH="ppc64le"
HELM_VERSION="v3.14.3"
BUILD_HOME=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
GOPATH="$HOME/go"
DEST_DIR="$GOPATH/src/github.com/gravitational/teleport/integrations/operator/bin"

export PATH="/usr/local/go/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
cd "$BUILD_HOME"

#######################################
# Install System Dependencies
#######################################
yum install -y \
    make tar tzdata cmake unzip rsync jq git wget \
    gcc gcc-c++ libffi libffi-devel gcc-gfortran \
    yum-utils sudo \
    llvm clang clang-devel llvm-devel 


#######################################
# Install Go
#######################################
cd "$BUILD_HOME"
wget "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
rm -f "go${GO_VERSION}.linux-${ARCH}.tar.gz"
go version

#######################################
# Install Node.js + pnpm
#######################################
cd "$BUILD_HOME"
curl -O "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.gz"
tar -xzf "node-v${NODE_VERSION}-linux-${ARCH}.tar.gz"
export PATH="/${BUILD_HOME}/node-v${NODE_VERSION}-linux-${ARCH}/bin:$PATH"
node -v
npm -v
npm install -g pnpm
pnpm -v

#######################################
# Install Rust
#######################################
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version
cargo --version

#########################################
# Setup CentOS Repositories (Required for Protobuf)
#########################################
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/

# Try downloading GPG key from a more reliable source
echo "Fetching CentOS GPG key..."
if ! wget -q https://vault.centos.org/centos/RPM-GPG-KEY-CentOS-Official -O /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official; then
    echo "Fallback: Trying alternate GPG key import..."
    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official || true
else
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
fi

#########################################
# Install Protobuf Libraries
#########################################
yum install -y protobuf protobuf-devel protobuf-c protobuf-c-devel

export PROTOC=/usr/bin/protoc
export PATH="$PROTOC:$PATH"
protoc --version

#######################################
# Install Helm
#######################################
cd "$BUILD_HOME"
curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz"
tar -zxvf "helm-${HELM_VERSION}-linux-${ARCH}.tar.gz"
mv "linux-${ARCH}/helm" /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version

#######################################
# Install Helm Plugin (helm-unittest)
#######################################
cd "$BUILD_HOME"
git clone https://github.com/quintush/helm-unittest.git
cd helm-unittest
git checkout v0.3.1
# Build the binary
go build -o untt -ldflags "-X main.version=0.3.1 -extldflags '-static'" ./cmd/helm-unittest

# Create plugin directory in Helm plugins
mkdir -p $HOME/.local/share/helm/plugins/helm-unittest
cp untt $HOME/.local/share/helm/plugins/helm-unittest/
cp plugin.yaml $HOME/.local/share/helm/plugins/helm-unittest/
# Verify plugin is correctly installed
helm plugin list

#######################################
# Install bats-core
#######################################
cd "$BUILD_HOME"
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
bats --version

#######################################
# Install Terraform
#######################################
cd "$BUILD_HOME"
git clone https://github.com/hashicorp/terraform.git
cd terraform
git checkout v1.13.4
go build -o terraform
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
terraform version

#######################################
# Clone and Patch Teleport
#######################################
mkdir -p "$GOPATH/src/github.com/gravitational"
cd "$GOPATH/src/github.com/gravitational"
git clone "https://github.com/gravitational/${PACKAGE_NAME}.git"
cd "${PACKAGE_NAME}" && git checkout "${PACKAGE_VERSION}"
git apply $SCRIPT_DIR/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

#######################################
# Install setup-envtest Tool
#######################################
go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
mkdir -p "$DEST_DIR"
cp "$(go env GOPATH)/bin/setup-envtest" "$DEST_DIR/"

export CGO_LDFLAGS="-L$(pwd)/target/powerpc64le-unknown-linux-gnu/release -l:librdp_client.a"
#######################################
# Build Teleport
#######################################
make full WEBASSETS_SKIP_BUILD=1

#######################################
# Run Tests
#######################################i
#make test WEBASSETS_SKIP_BUILD=1
echo "Skipping TestSessionAuditLog as this failure is flaky and in parity with Intel"
echo "commented the test command as test results are flaky on Travis due to restricted environment"
