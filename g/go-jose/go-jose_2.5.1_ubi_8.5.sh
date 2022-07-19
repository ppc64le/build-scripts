#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: go-jose
# Version	: v2.5.1
# Source repo	: https://github.com/square/go-jose
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

PACKAGE_NAME="go-jose"
PACKAGE_VERSION=${1:-"v2.5.1"}
PACKAGE_URL="https://github.com/square/go-jose"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.12"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}

export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT="$GOPATH/src/github.com/square/"

echo "installing dependencies from system repo"
dnf install -qy wget git gcc-c++ findutils python38

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

mkdir -p "$PACKAGE_SOURCE_ROOT"
cd "$PACKAGE_SOURCE_ROOT"

if ! git clone "$PACKAGE_URL" "$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"
export GO111MODULE=off
COMMIT_DATE=$(git log -1 --pretty="%cI")
export COMMIT_DATE
go get ./... | true
go get github.com/google/go-cmp/cmp || true 
go get github.com/stretchr/testify/assert || true 
find "$GOPATH" -name ".git" -exec sh -c -x 'cd $(dirname $1) && git log -1 --before="$COMMIT_DATE" --pretty="%h" | xargs git checkout ' _ {} \; || true
git checkout "$PACKAGE_VERSION"

if ! go install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

go test . -v -covermode=count -coverprofile=profile.cov
go test ./cipher -v -covermode=count -coverprofile=cipher/profile.cov
go test ./jwt -v -covermode=count -coverprofile=jwt/profile.cov
go test ./json -v # no coverage for forked encoding/json package
cd jose-util && go build
go install 
python3 -m pip install cram
python3 -m cram -v jose-util.t # cram tests jose-util
cd ..

if ! go test -v ./...; then
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
