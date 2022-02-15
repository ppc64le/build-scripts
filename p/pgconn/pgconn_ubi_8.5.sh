#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pgconn
# Version       : v1.6.1
# Source repo   : https://github.com/jackc/pgconn.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./pgconn_ubi_8.5.sh v1.6.1(version_to_test)
PACKAGE_NAME=pgconn
PACKAGE_VERSION=v1.6.1
PACKAGE_URL=https://github.com/jackc/pgconn.git


dnf install git -y

docker run --name postgres-server -e POSTGRES_PASSWORD=password -d postgres

IP_PG_SERVER=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" postgres-server)

echo $ip_of_pg_server


PACKAGE_VERSION=${1:-v1.6.1}

# Install Go and setup working directory
wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

INSTALL_SUCCESS="false"


if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi


# Ensure go.mod file exists
if ! PGX_TEST_CONN_STRING="host=$IP_PG_SERVER dbname=postgres user=postgres password=password" go test -v -race ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

