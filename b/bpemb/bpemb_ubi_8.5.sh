#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: bpemb
# Version	: 9bcde40
# Source repo   : https://github.com/bheinzerling/bpemb.git
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Abhishek Dighe <Abhishek.Dighe@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=bpemb
PACKAGE_VERSION=${1:-9bcde40}
PACKAGE_URL=https://github.com/bheinzerling/bpemb.git

yum install -y wget git

#conda installtion
wget https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-ppc64le.sh
bash Anaconda3-2022.05-Linux-ppc64le.sh -b
source /root/anaconda3/bin/activate

if ! git clone $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Github| Fail |  Clone_Fails" 
fi

cd $PACKAGE_NAME

# installing pre-requisite packages
conda install --file requirements.txt -y

python setup.py install

if ! python setup.py test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Both_Install_and_Test_Success"
fi 


