#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : MACS
# Version          : v3.0.0
# Source repo      : https://github.com/macs3-project/MACS/
# Tested on        : UBI 8.7
# Language         : Cython, Python
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=MACS
PACKAGE_VERSION=${1:-v3.0.0}
PACKAGE_URL=https://github.com/macs3-project/MACS/

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y wget gcc git gcc-c++ gcc-gfortran.ppc64le openblas.ppc64le cmake procps-ng diffutils bc

wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
python3 -m pip install -U pip

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

conda install openblas cython numpy scipy -y
conda install conda-forge::meson-python -y
conda install conda-forge::pybind11 -y
conda install conda-forge::pythran -y
conda install conda-forge::cython -y
yum install zlib-devel -y
python3 -m pip install --upgrade --progress-bar off pytest

if ! python3 -m pip install --upgrade-strategy only-if-needed --no-build-isolation --progress-bar off . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest --runxfail && cd test && ./cmdlinetest-nohmmratac macs3 ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi