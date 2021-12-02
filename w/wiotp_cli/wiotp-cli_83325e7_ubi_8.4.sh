#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package	: ibm-watson-iot/iot-python
# Version	: 
# Source repo	: https://github.com/ibm-watson-iot/iot-python
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <saurabh.gore@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
WORK_DIR=`pwd`
PACKAGE_NAME=iot-python
PACKAGE_VERSION=83325e79e9078a3f5dbff0061c9ee98869d9a6c8        #commit-hash 
PACKAGE_URL=https://github.com/ibm-watson-iot/iot-python.git


# Following credentials will require to test the package
echo -n  "Please enter WIOTP_API_KEY"
read  WIOTP_API_KEY
echo -n "Please enter WIOTP_API_TOKEN"
read  WIOTP_API_TOKEN


# To set WIOTP_API_KEY and WIOTP_API_TOKEN
	# -will require ibm cloud account
	# -create service ibm internet of things ( https://cloud.ibm.com/catalog/services/internet-of-things-platform )
	# -launch service and generate api keys and api-auth token 
	#  refer link ( https://developer.ibm.com/tutorials/iot-generate-apikey-apitoken/ )



export WIOTP_API_KEY
export WIOTP_API_TOKEN


# install dependencies
yum -y update && yum install -y python36 python36-devel python2 python2-devel git

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/clone_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
    	exit 0
fi

cd $WORK_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION .                            # added . at last to fetch all files from commit
if ! python3 setup.py install; then
	exit 0
fi


cd $WORK_DIR/$PACKAGE_NAME
python3 -m pip install tox 
if ! tox -e py36; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "  > $WORK_DIR/output/test_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" > $WORK_DIR/output/version_tracker
	echo "read instruction at the end of script to remove test failures."
	exit 0
else
	echo "------	------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "  > $WORK_DIR/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > $WORK_DIR/output/version_tracker
	exit 0
fi

# test_application_cfg.py , test_device_cfg.py will fail as its trying to connect without parameters 



# If test-cases failed 
# 1)# launch ibm iot service 
	# Navigate through Security > Connection security > Default role
	# and set Security level to TLS-Optional
# 2)# Navigate through Settings > Last event Cache 
	# and Activate Last event cache  also set Client Connection State API to active
