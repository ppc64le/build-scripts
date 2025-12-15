# -----------------------------------------------------------------------------
#
# Package       : github.com/envoyproxy/go-control-plane
# Version       : v0.9.0, v0.9.7
# Source repo   : https://github.com/envoyproxy/go-control-plane.git
# Tested on     : UBI 8.5
# Language      : GO
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Baheti (aramswar@in.ibm.com)
#
# Disclaimer    : This script has been tested in root mode on given
# ==========    platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=github.com/envoyproxy/go-control-plane
#Setting the default version v0.9.7
PACKAGE_VERSION=${1:-v0.9.7}
PACKAGE_PATH=https://github.com/envoyproxy/go-control-plane.git

#Install golang if not found
if ! command -v go &> /dev/null
then
    yum install -y golang
fi

mkdir -p /root/output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export GOPATH="$(go env GOPATH)"
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
if go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
    
    cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)
    
    echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
    # Ensure go.mod file exists
    [ ! -f go.mod ] && go mod init
    if ! go test ./...; then
            exit 1
    else
            echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
            echo "$PACKAGE_VERSION $PACKAGE_NAME" > /root/output/test_success 
            echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /root/output/version_tracker
            exit 0
    fi
fi
