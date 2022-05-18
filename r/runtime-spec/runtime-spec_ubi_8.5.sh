#!/bin/bash   -e
# -----------------------------------------------------------------------------
#
# Package	: runtime-spec
# Version	: v1.0.2
# Source repo	: https://github.com/opencontainers/runtime-spec
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : True
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

PACKAGE_NAME="runtime-spec"
PACKAGE_VERSION=${1:-"v1.0.2"}
PACKAGE_URL="https://github.com/opencontainers/runtime-spec"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.18"}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin

dnf -q install -y wget zip make git
dnf install -qy http://mirror.chpc.utah.edu/pub/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.chpc.utah.edu/pub/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf config-manager --enable powertools
dnf install -qy pandoc texlive-latex texlive-latex-fonts texlive-ec texlive-gsftopk texlive-updmap-map golang

export PATH="$(go env GOPATH)/bin:${PATH}"
set -x
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
# Fix for "cannot find main module" issue
go mod init github.com/opencontainers/runtime-spec
go get golang.org/x/lint/golint
go install golang.org/x/lint/golint
go get github.com/vbatts/git-validation
go install github.com/vbatts/git-validation
go get -d ./schema/...
if ! make; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

go mod tidy
#make install.tools

make .govet
make .golint

make .gitvalidation
make docs

if ! make -C schema test; then
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
