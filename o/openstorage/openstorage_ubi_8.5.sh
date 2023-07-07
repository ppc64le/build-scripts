#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: openstorage
# Version	: main (6cee235f13a6fc56cab84c57871d02ae1ed4a327)
# Source repo	: https://github.com/libopenstorage/openstorage
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="openstorage"
PACKAGE_VERSION=${1:-"6cee235f13a6fc56cab84c57871d02ae1ed4a327"}
PACKAGE_URL="https://github.com/libopenstorage/openstorage"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
ARCH="ppc64le"

export GO_VERSION=${GO_VERSION:-"1.15"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT="$GOPATH/src/github.com/libopenstorage"
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -q -y wget zip make git gcc-c++ make

echo "adding fedora repo..."
dnf install -qy http://pubmirror1.math.uh.edu/fedora-buffet/archive/fedora-secondary/updates/29/Everything/ppc64le/Packages/f/fedora-gpg-keys-29-6.noarch.rpm

tee /etc/yum.repos.d/fedora.repo <<-config
	[fedora]
	name=Fedora 29 - \$basearch
	baseurl=http://download.fedoraproject.org/pub/fedora/linux/releases/29/Everything/\$basearch/os/
	metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-29&arch=\$basearch
	enabled=1
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-29-\$basearch

	[updates]
	name=Fedora 29 - \$basearch - Updates
	baseurl=http://download.fedoraproject.org/pub/fedora/linux/updates/29/Everything/\$basearch/
	metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f29&arch=\$basearch
	enabled=1
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-29-\$basearch
config

dnf install -qy e2fsprogs

if [ -d "$GOPATH" ]; then
    rm -rf "$GOPATH"
    rm -rf "$GOROOT"
fi

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-${ARCH}.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-${ARCH}.tar.gz
rm -f go"$GO_VERSION".linux-${ARCH}.tar.gz

mkdir -p "$PACKAGE_SOURCE_ROOT"
cd "$PACKAGE_SOURCE_ROOT"
git clone -q $PACKAGE_URL
cd "$PACKAGE_SOURCE_ROOT"/$PACKAGE_NAME
git checkout "$PACKAGE_VERSION"

if ! make; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
