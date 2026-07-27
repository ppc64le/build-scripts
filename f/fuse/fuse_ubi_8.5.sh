#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fuse
# Version	: v0.0.0-20160811212531-371fbbdaa898
# Source repo	: https://proxy.golang.org/bazil.org/fuse/@v/v0.0.0-20160811212531-371fbbdaa898.zip
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

# creating non-root user
useradd -p "" -G wheel ubi
dnf -q install sudo -y
sudo -i -u ubi bash <<-SCRIPT
set -e 


PACKAGE_NAME="fuse"
PACKAGE_VERSION=\${1:-"v0.0.0-20160811212531-371fbbdaa898"}
PACKAGE_URL="https://proxy.golang.org/bazil.org/fuse/@v/\$PACKAGE_VERSION.zip"
OS_NAME=\$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


export GO_VERSION=\${GO_VERSION:-"1.9"}
export GOROOT=\${GOROOT:-"/usr/local/go"}
export GOPATH=\${GOPATH:-\$HOME/go}
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=\$(awk -F '/' '{print  "/src/" \$4 "/" ;}' <<<"\$PACKAGE_URL" | xargs printf "%s" "\$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
sudo dnf -q install -y wget git zip fuse 

if [ -d "\$GOPATH" ]; then
    rm -rf "\$GOPATH"
    sudo rm -rf "\$GOROOT"
fi

# installing golang
wget https://golang.org/dl/go"\$GO_VERSION".linux-ppc64le.tar.gz
sudo tar -C /usr/local/ -xzf go"\$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"\$GO_VERSION".linux-ppc64le.tar.gz

wget https://proxy.golang.org/bazil.org/fuse/@v/v0.0.0-20160811212531-371fbbdaa898.zip
echo "\$PACKAGE_SOURCE_ROOT"
mkdir -p "\$PACKAGE_SOURCE_ROOT"
unzip -q ./*.zip -d "\$GOPATH"/src
cd "\$PACKAGE_SOURCE_ROOT"
mv \$PACKAGE_NAME* \$PACKAGE_NAME
cd \$PACKAGE_NAME
go get ./...
if ! go install; then
    echo "------------------\$PACKAGE_NAME:install_fails-------------------------------------"
    echo "\$PACKAGE_URL \$PACKAGE_NAME"
    echo "\$PACKAGE_NAME  |  \$PACKAGE_URL | \$PACKAGE_VERSION | \$OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! go test; then
    echo "------------------\$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "\$PACKAGE_URL \$PACKAGE_NAME"
    echo "\$PACKAGE_NAME  |  \$PACKAGE_URL | \$PACKAGE_VERSION | \$OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------\$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "\$PACKAGE_URL \$PACKAGE_NAME"
    echo "\$PACKAGE_NAME  |  \$PACKAGE_URL | \$PACKAGE_VERSION | \$OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
SCRIPT
