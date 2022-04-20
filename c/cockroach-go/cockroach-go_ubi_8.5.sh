#!/bin/bash -ex

# ----------------------------------------------------------------------------
#
# Package               : cockroach-go
# Version               : v2.2.8
# Source repo           : https://github.com/cockroachdb/cockroach-go
# Tested on             : UBI 8.5
# Language              : GO
# Script License        : Apache License, Version 2 or later
# Travis-Check          : False
# Maintainer            : Prashant Khoje <Prashant.Khoje@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Dependency installation
dnf install -y git wget patch diffutils unzip gcc-c++ make cmake autoconf \
    ncurses-devel libarchive curl openssl-devel procps-ng xz python2

dnf install -y \
    http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm \
    http://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/c/ccache-3.7.7-1.el8.ppc64le.rpm

DISTRO=linux-ppc64le

cd $HOME
# Install nodejs
NODE_VERSION=v12.20.1
wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz
tar -xzf node-$NODE_VERSION-$DISTRO.tar.gz
export PATH=$HOME/node-$NODE_VERSION-$DISTRO/bin:$PATH

npm install yarn --global
rm -f node-$NODE_VERSION-$DISTRO.tar.gz

cd $HOME
# Setup go environment and install go
GOPATH=$HOME/go
COCKROACH_HOME=$GOPATH/src/github.com/cockroachdb
mkdir -p $COCKROACH_HOME
export GOPATH
curl -O https://dl.google.com/go/go1.16.5.$DISTRO.tar.gz
tar -C /usr/local -xzf go1.16.5.$DISTRO.tar.gz
rm -f go1.16.5.$DISTRO.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Cockcroach-go tests require cockroachdb. Since community only provides amd64 binaries, we need to build cockroachdb.
COCKROACH_VERSION=v21.2.9
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout $COCKROACH_VERSION
make buildoss
make install

# Set variables
PACKAGE_URL=https://github.com/cockroachdb/cockroach-go
#PACKAGE_VERSION is configurable can be passed as an argument.
#PACKAGE_VERSION=${1:-e0a95dfd547c} - Build: PASS, Tests: FAIL 
PACKAGE_VERSION=${1:-v2.2.8}
PACKAGE_NAME=cockroach-go
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Install go package and update go path if not installed
GO_VERSION=1.16.1
if ! command -v go &> /dev/null
then
    curl -O https://dl.google.com/go/go$GO_VERSION.$DISTRO.tar.gz
    tar -C /usr/local -xzf go$GO_VERSION.$DISTRO.tar.gz
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
    export GO111MODULE=auto
    rm -f go$GO_VERSION.$DISTRO.tar.gz
fi

cd $COCKROACH_HOME
# Check if package exists
if [ -d $PACKAGE_NAME ] ; then
    rm -rf $PACKAGE_NAME
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package source"
fi

# Download the repos
git clone $PACKAGE_URL

# Build and Test
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
    echo "-------------------------- Switched to $PACKAGE_VERSION -------------------- "
else
    echo "-------------------------- $PACKAGE_VERSION is not found. ----------------------------"
    exit
fi

# Ensure go.mod file exists
[ ! -f go.mod ] && go mod init $PACKAGE_NAME
go mod tidy

if ! go build -v ./...; then
    echo "-------------------------- $PACKAGE_NAME: build failed --------------------------"
    exit 1
fi

which cockroach
#export COCKROACH_BINARY=`which cockroach`
export COCKROACH_BINARY=/usr/local/bin/cockroach
$COCKROACH_BINARY --version
if ! go test -v ./...; then
    echo "-------------------------- $PACKAGE_NAME: test faile --------------------------"
    exit 1
else
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success" 
    exit 0
fi

# Build fails on travis-ci due to timeout. Hence travis-ci build is disabled.
# The build is successful on a VM:
# [root@p006vm78 cockroach-go]# grep PASS 44-dbgo.txt
# --- PASS: TestMaxRetriesExceededError (0.00s)
# --- PASS: TestExecuteTx (0.94s)
# --- PASS: TestConfigureRetries (0.00s)
# PASS
# --- PASS: TestExecuteTx (1.00s)
# PASS
# --- PASS: TestExecuteTx (0.85s)
# PASS
# --- PASS: TestExecuteTx (0.98s)
# PASS
# --- PASS: TestRunServer (72.92s)
#     --- PASS: TestRunServer/Insecure (0.89s)
#     --- PASS: TestRunServer/InsecureWithCustomizedMemSize (0.66s)
#     --- PASS: TestRunServer/SecureClientCert (2.91s)
#     --- PASS: TestRunServer/SecurePassword (2.54s)
#     --- PASS: TestRunServer/InsecureTenantStoreOnDisk (8.90s)
#     --- PASS: TestRunServer/SecureTenantStoreOnDisk (13.89s)
#     --- PASS: TestRunServer/InsecureTenant (1.21s)
#     --- PASS: TestRunServer/SecureTenant (2.97s)
#     --- PASS: TestRunServer/SecureTenantCustomPassword (3.90s)
#     --- PASS: TestRunServer/InsecureNonStable (0.64s)
#     --- PASS: TestRunServer/InsecureWithCustomizedMemSizeNonStable (0.64s)
#     --- PASS: TestRunServer/SecureClientCertNonStable (2.10s)
#     --- PASS: TestRunServer/SecurePasswordNonStable (2.97s)
#     --- PASS: TestRunServer/InsecureTenantStoreOnDiskNonStable (9.17s)
#     --- PASS: TestRunServer/SecureTenantStoreOnDiskNonStable (9.59s)
#     --- PASS: TestRunServer/SecureTenantThroughProxyNonStable (4.34s)
#     --- PASS: TestRunServer/SecureTenantThroughProxyCustomPasswordNonStable (5.58s)
# --- PASS: TestPGURLWhitespace (0.64s)
# --- PASS: TestTenant (1.13s)
# --- PASS: TestFlockOnDownloadedCRDB (5.73s)
#     --- PASS: TestFlockOnDownloadedCRDB/DownloadPassed (4.18s)
#     --- PASS: TestFlockOnDownloadedCRDB/DownloadKilled (1.55s)
# PASS
# [root@p006vm78 cockroach-go]# grep FAIL 44-dbgo.txt
# [root@p006vm78 cockroach-go]#
