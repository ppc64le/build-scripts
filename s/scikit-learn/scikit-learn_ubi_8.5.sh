#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: scikit-learn
# Version	: 1.0.2
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Reynold Vaz <Reynold.Vaz@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.0.2}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git

yum install git wget make gcc gcc-c++ -y

#conda installation
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
export PATH=$HOME/conda/bin/:$PATH
conda init bash
source ~/.bashrc

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

mkdir -p /home/tester && cd /home/tester
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing dependencies
conda install numpy scipy joblib threadpoolctl -y
conda install cython pytest -y

#building scikit-learn package
make clean
make inplace

export SKLEARN_SKIP_OPENMP_TEST=1

#Test test_mlp_regressor_dtypes_casting deselected
#Numerical instability due to numerical difference caused by the test.
if ! pytest sklearn -k 'not test_mlp_regressor_dtypes_casting' ; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Both_Install_and_Test_Success"
fi 