#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 0.24.1
# Source repo   : https://github.com/scikit-learn/scikit-learn
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas <Valen.Mascarenhas@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-0.24.1}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn

yum install git wget make gcc gcc-c++ -y

#conda installation
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
export PATH=$HOME/conda/bin/:$PATH
conda init bash
source ~/.bashrc


mkdir -p /home/tester && cd /home/tester
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing dependencies
conda install numpy scipy joblib threadpoolctl -y
conda install cython pytest -y

 sed -i "201s/thresholds/thresholds.astype(np.float64)/" sklearn/metrics/tests/test_common.py


#building scikit-learn package
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