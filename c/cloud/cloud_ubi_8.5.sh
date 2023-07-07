#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: cloud
# Version	: v0.0.0-20151119220103-975617b05ea8
# Source repo	: https://code.googlesource.com/gocloud
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

PACKAGE_NAME="cloud"
PACKAGE_VERSION=${1:-"v0.0.0-20151119220103-975617b05ea8"}
PACKAGE_URL="https://code.googlesource.com/gocloud"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.9"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}

export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT="$GOPATH/src/google.golang.org"
DATE=${DATE:-$(cut -d '-' -f2 <<<"$PACKAGE_VERSION" | sed -e "s/\(....\)\(..\)\(..\)\(.\)/\1-\2-\3-\4/")}
export DATE

echo "installing dependencies from system repo"
dnf install -q -y wget git gcc-c++ diffutils

echo "installing golang $GO_VERSION"
wget -q https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

git clone -q https://github.com/golang/protobuf "$GOPATH"/src/github.com/golang/protobuf
cd "$GOPATH"/src/github.com/golang/protobuf
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout

git clone -q https://go.googlesource.com/text "$GOPATH"/src/golang.org/x/text
cd "$GOPATH"/src/golang.org/x/text
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://go.googlesource.com/oauth2 "$GOPATH"/src/golang.org/x/oauth2
cd "$GOPATH"/src/golang.org/x/oauth2
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://go.googlesource.com/net "$GOPATH"/src/golang.org/x/net
cd "$GOPATH"/src/golang.org/x/net
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout

git clone -q https://github.com/grpc/grpc-go "$GOPATH"/src/google.golang.org/grpc
cd "$GOPATH"/src/google.golang.org/grpc
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://github.com/golang/appengine "$GOPATH"/src/google.golang.org/appengine
cd "$GOPATH"/src/google.golang.org/appengine
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://github.com/googleapis/google-api-go-client "$GOPATH"/src/google.golang.org/api
cd "$GOPATH"/src/google.golang.org/api
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://github.com/googleapis/go-genproto "$GOPATH"/src/google.golang.org/genproto
cd "$GOPATH"/src/google.golang.org/genproto
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://go.googlesource.com/protobuf "$GOPATH"/src/google.golang.org/protobuf
cd "$GOPATH"/src/google.golang.org/protobuf
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout
git clone -q https://github.com/googleapis/google-cloud-go "$GOPATH"/src/cloud.google.com/go
cd "$GOPATH"/src/cloud.google.com/go
git log -1 --before="$DATE" --pretty="%h" | xargs git checkout

echo "cloning..."
if ! git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT/$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$(cut -d '-' -f3 <<<"$PACKAGE_VERSION")"
export GO111MODULE=off

if ! go install ./...; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! go test ./...; then
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
