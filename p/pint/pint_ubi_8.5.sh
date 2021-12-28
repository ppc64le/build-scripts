# -----------------------------------------------------------------------------
#
# Package	: pint
# Version	: 0.18
# Source repo	: https://github.com/hgrecco/pint
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pint
PACKAGE_VERSION=${1:-0.18}
PACKAGE_URL=https://github.com/hgrecco/pint

yum install -y git python38 wget

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda3-latest-Linux-ppc64le.sh -b -p /conda
export PATH=$PATH:/conda/bin
conda update -y -n base conda
conda create -n pint -y python=3.8
eval "$(/conda/bin/conda shell.bash hook)"
conda init bash
conda activate pint

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

cd $HOME_DIR

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME= | Fail |  Clone_Fails"
    	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Package Requirements
conda install -y -c conda-forge --file requirements_docs.txt
conda install -y -c conda-forge uncertainties pytest-cov pytest-subtests Babel=2.8.1

if ! python setup.py install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! pytest -rfsxEX -s --cov=pint --cov-config=.coveragerc; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_check_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Check_and_Test_Success"
	exit 0
fi
