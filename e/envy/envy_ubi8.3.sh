#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Package        : Envy
# Version        : 1.7.1 - latest
# Source repo    : https://github.com/gobuffalo/envy
# Tested on      : Ubi 8.3 + Go latest version (v1.7.1)
# Script License : Apache 2.0
# Maintainer     : Eshant Gupta <eshant.gupta@ibm.com>; Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Usage: ./envy_ubi_8.3.sh
#                  OR
# 	 ./envy_ubi_8.3.sh v1.7.1

set -e
test -f ~/.bashrc && source ~/.bashrc
set_env=false

# Get sudo access
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

function usage() {
	echo "$1 accepts 0 or maximum 1 argument"
	exit 1
}

if [ "$#" -gt 1	]
then
	usage "$(basename $0)"
else
	[ -n "$1" ] && export TAGS="$1" || export TAGS=""
fi

# check installed Golang
go_version=$(go version | { read _ _ v _; echo ${v#go}; })
[[ "$(printf '%s\n' "$go_version" "1.16" | sort -V | head -n1)" = "1.16" ]] && set_env=true

# setup Golang
if ! $set_env
then

    cd "$HOME"
    mkdir -p golang go && yum install git wget curl make gcc -y
    [ $? != 0 ] && echo "Installation Failed" && exit 1

    echo "Finding latest version of Go for PPC64LE..."
    latest=$(curl https://golang.org/VERSION?m=text)

    echo "Downloading latest Go for PPC64LE: ${latest}"
    $(wget https://dl.google.com/go/${latest}.linux-ppc64le.tar.gz)
    tar -C golang -xzf "${latest}".linux-ppc64le.tar.gz

    echo "Create the skeleton for your local users go directory"
    mkdir -p go/{bin,pkg,src}

    echo "Setting up GOPATH"
    export GOPATH=${GOPATH:-$HOME/go}

    echo "Setting up GOROOT"
    export GOROOT=$HOME/golang/go

    echo "Setting PATH to include golang binaries"
    export PATH=$PATH:$GOPATH/bin:$GOROOT/bin

fi

# install envy package
GO111MODULE="off" go get github.com/gobuffalo/envy
cd $GOPATH/src/github.com/gobuffalo/envy
make deps && make build && make test
make install
echo "---------------------------"
echo "Envy installed successfully"
echo "---------------------------"
exit 0
