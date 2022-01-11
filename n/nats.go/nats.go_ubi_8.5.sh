# -----------------------------------------------------------------------------
#
# Package	: nats.go
# Version	: v1.10.0
# Source repo	: https://github.com/nats-io/nats.go
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Ghumnar / Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=github.com/nats-io/nats.go
PACKAGE_VERSION=${1:-v1.10.0}
PACKAGE_URL=https://github.com/nats-io/nats.go

yum install -y git golang

#Setup working directory
mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

cd /home/tester
mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

function test_with_master_without_flag_u(){
	echo "Building $PACKAGE_PATH with master branch"
    export GO111MODULE=auto
	if ! go get -d -t $PACKAGE_NAME; then
        	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
        	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
        	exit 1
	else
		cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)
        echo "Testing $PACKAGE_PATH with master branch without flag -u"
		# Ensure go.mod file exists
		go mod init
		if ! go test ./...; then
		        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
		        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		        exit 1
		else		
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
		        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        		exit 0
		fi
	fi
}

function test_with_master(){
	echo "Building $PACKAGE_PATH with master"
	export GO111MODULE=auto
	if ! go get -d -u -t $PACKAGE_NAME; then
		test_with_master_without_flag_u
		exit 0
	fi

	cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)
	echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
	# Ensure go.mod file exists
	go mod init
	if ! go test ./...; then
		test_with_master_without_flag_u
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		exit 0
	fi
}

function test_without_flag_u(){
	echo "Building $PACKAGE_PATH with $PACKAGE_VERSION and without -u flag"
	if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
		test_with_master
		exit 0
	fi

	cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)
	echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
	# Ensure go.mod file exists
	go mod init
	if ! go test ./...; then
		test_with_master
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		exit 0
	fi
}

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
if ! go get -d -u -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	test_without_flag_u
	exit 0
fi

cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
#Download all the dependencies
go mod tidy
if ! go test -race ./... ; then
	test_with_master
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
