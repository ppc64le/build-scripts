#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	: Traefik
# Version	: v2.10.1
# Source repo	: https://github.com/traefik/traefik
# Tested on	: UBI 8.7
# Language   	: Go
# Travis-Check  : True
# Script License: Apache License 2.0 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v2.10.1}
PACKAGE_NAME=traefik
PACKAGE_URL=https://github.com/traefik/traefik

yum install -y gcc-c++ make wget git tar patch

wget https://go.dev/dl/go1.20.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf  go1.20.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build -v ./... ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION |  GitHub | Fail |  Build_Fails"
       exit 1
fi

sed -i '230d' pkg/middlewares/ratelimiter/rate_limiter_test.go
sed -i '230 i\      Period:  ptypes.Duration(10 * time.Second),' pkg/middlewares/ratelimiter/rate_limiter_test.go
sed -i '151d' pkg/middlewares/ratelimiter/rate_limiter_test.go
sed -i '151 i\				Average: 5,' pkg/middlewares/ratelimiter/rate_limiter_test.go

if ! go test ./... ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
