#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-i18n
# Version	: v1.10.0, v1.9.0
# Source repo	: https://github.com/nicksnyder/go-i18n
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

PACKAGE_NAME="go-i18n"
PACKAGE_VERSION=${1:-"v1.10.0"}
PACKAGE_URL="https://github.com/nicksnyder/go-i18n"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.9"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -y wget git -y >/dev/null

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

#installing packages dependencies from source
git clone https://github.com/pelletier/go-toml "$GOPATH"/src/github.com/pelletier/go-toml
cd "$GOPATH"/src/github.com/pelletier/go-toml
git checkout 5ccdfb18c776b740aecaf085c4d9a2779199c279
git clone https://github.com/go-yaml/yaml "$GOPATH"/src/gopkg.in/yaml.v2
cd "$GOPATH"/src/gopkg.in/yaml.v2
git checkout 7649d4548cb53a614db133b2a8ac1f31859dda8c
git clone -q https://github.com/pelletier/go-buffruneio "$GOPATH"/src/github.com/pelletier/go-buffruneio
cd "$GOPATH"/src/github.com/pelletier/go-buffruneio
git checkout c37440a7cf42ac63b919c752ca73a85067e05992

if ! git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION" || exit 1

if ! go install ./goi18n ./i18n; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! go test ./goi18n ./i18n; then
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
