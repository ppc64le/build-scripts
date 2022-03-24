#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: glfw
# Version	: e6da0acd62b1
# Source repo	: https://github.com/go-gl/glfw
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=glfw
PACKAGE_VERSION=${1:-e6da0acd62b1}
PACKAGE_URL=https://github.com/go-gl/glfw

yum install -y sudo
sudo yum install -y wget git golang gcc-c++

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH

sudo dnf -y install dnf-plugins-core
sudo dnf -y upgrade 
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf config-manager --set-enabled powertools
sudo yum install  xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps mesa-libGL libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel freeglut-devel glibc-static libXi-devel libXxf86vm-devel -y

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init go-gl/glfw
go mod tidy

if ! go get -t -v ./v3.2/...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Init_Fails"
fi

if ! go build ./v3.2/...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Init_Fails"
fi

if ! go test -v -race ./v3.2/...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
fi

#Build passes on VM but fails Travis check with sudo command not found error


