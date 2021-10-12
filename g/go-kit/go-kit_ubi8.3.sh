#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Package        : go-kit
# Version        : 0.9.0 - latest
# Source repo    : https://github.com/go-kit/kit
# Tested on      : Ubi 8.3 + Go latest version (v1.7.1)
# Script License : Apache 2.0
# Maintainer     : Eshant Gupta <eshant.gupta@ibm.com>; Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in both root and user mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Usage: ./go-kit_ubi_8.3.sh
#                  OR
#        ./go-kit_ubi_8.3.sh v3.5.0
# ----------------------------------------------------------------------------

set_env=false

# Get sudo access
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

function usage() {
        echo "$1 accepts 0 or maximum 1 argument"
        echo "Usage:"
        echo "  $./go-kit_ubi_8.3.sh"
        echo "          OR"
        echo "  $./go-kit_ubi_8.3.sh v0.9.0"
        exit 1
}

if [ "$#" -gt 1 ]
then
        usage "$(basename $0)"
else
        [ -n "$1" ] && export TAGS="$1" || export TAGS=""
fi

# check installed Golang
[ -n $(which go) ] && [[ $(go version) > 1.6 ]] && set_env=true

# setup Golang
if ! $set_env
then

    cd "$HOME"
    mkdir golang go
    sudo yum install git wget curl make gcc -y
    [ $? != 0 ] && echo "Installation Failed" && exit 1

    echo "Finding latest version of Go for PPC64LE..."
    latest=$(curl https://golang.org/VERSION?m=text)

    echo "Downloading latest Go for PPC64LE: ${latest}"
    $(wget https://dl.google.com/go/${latest}.linux-ppc64le.tar.gz)
    tar -C golang -xzf "${latest}".linux-ppc64le.tar.gz

    echo "Create the skeleton for your local users go directory"
    mkdir -p go/{bin,pkg,src}

    echo "Setting up GOPATH"
    echo "export GOPATH=$HOME/go" >> .bashrc && source .bashrc

    echo "Setting up GOROOT"
    echo "export GOROOT=$HOME/golang/go" >> .bashrc && source .bashrc

    echo "Setting PATH to include golang binaries"
    echo "export PATH='$PATH':$GOROOT/bin:$GOPATH/bin" >> .bashrc && source .bashrc

fi

# install kit package
GO111MODULE="off" go get github.com/go-kit/kit
cd $GOPATH/src/github.com/go-kit/kit
# v0.9.0
[ "$TAGS" = "v0.9.0" ] && export GO111MODULE="off"
[ -n "$TAGS" ] && git checkout "$TAGS" -b new_branch && go get -v ./...
go test -v ./... && go build -v ./...
[ $? != 0 ] && exit 1
go install -v ./...
[ $? != 0 ] && exit 1
echo "---------------------------"
echo "go-kit installed successfully"
echo "---------------------------"
exit 0
