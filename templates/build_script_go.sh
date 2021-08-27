# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME={package_name}
PACKAGE_VERSION={package_version}
PACKAGE_URL={package_url}

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++

wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

mkdir -p /home/tester/$PACKAGE_NAME

cd /home/tester/$PACKAGE_NAME
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

function test_with_master(){
	echo "Building $PACKAGE_PATH with master branch"
        export GO111MODULE=auto
	if ! go get -d -u -t $PACKAGE_NAME; then
        	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        	echo "$PACKAGE_VERSION $PACKAGE_NAME"
        	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails"
        	exit 0
	else
		cd $GOPATH/src/$PACKAGE_NAME
                echo "Testing $PACKAGE_PATH with master branch"
		if ! go test; then
		        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		        echo "$PACKAGE_VERSION $PACKAGE_NAME"
		        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
		        exit 0
		else		
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		        echo "$PACKAGE_VERSION $PACKAGE_NAME"
		        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        		exit 0
		fi
	fi


}

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
if ! go get -d -u -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	test_with_master
	exit 0
fi

cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
if ! go test; then
	test_with_master
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
