#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : google-cloud
# Version       : v0.54.0, v0.93.3
# Source repo   : https://github.com/googleapis/google-cloud-go
# Tested on     : ubi 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="google-cloud-go"
PACKAGE_VERSION=${1:-"v0.54.0"}
PACKAGE_URL="https://github.com/googleapis/google-cloud-go"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.17.4"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -y wget git gcc-c++ make diffutils >/dev/null

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz


if ! git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION" || exit 1
export GO111MODULE=on

#patch
sed -i -e 's/.Rip/.Nip/g' cmd/go-cloud-debug-agent/internal/debug/server/server.go
sed -i -e 's/.Rsp/.Gpr[0]/g' cmd/go-cloud-debug-agent/internal/debug/server/server.go


if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

#Test is in parity with intel. 
# smoke_test.go:270: google: could not find default credentials. See https://developers.google.com/accounts/docs/application-default-credentials for more information.
 #--- FAIL: TestIntegration_HTTPR (0.00s) 
   #integration_test.go:48: set GCLOUD_TESTS_GOLANG_PROJECT_ID and GCLOUD_TESTS_GOLANG_KEY
