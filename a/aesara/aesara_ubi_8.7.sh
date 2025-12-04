#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : aesara
# Version          : rel-2.9.3
# Source repo      : https://github.com/aesara-devs/aesara
# Tested on        : UBI 8.7
# Language         : Python
# Ci-Check     : True
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

PACKAGE_NAME=aesara
PACKAGE_VERSION=${1:-rel-2.9.3}
PACKAGE_URL=https://github.com/aesara-devs/aesara

PYTHON_VERSION=3.9

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum update -y
yum install wget git gcc gcc-c++ -y

# miniconda installation
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
# conda --version
# python3 --version
python3 -m pip install -U pip
python3 -m pip install build

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 -m build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

conda install --yes -q -c conda-forge "python~=3.9=*_cpython" "numpy>=1.23.5" scipy pip graphviz cython pytest coverage pytest-cov pytest-benchmark sympy filelock etuples logical-unification miniKanren cons typing_extensions "setuptools>=48.0.0"
conda install --yes -q -c conda-forge -c numba "python~=${PYTHON_VERSION}=*_cpython" "numba>=0.57.0"
# conda install --yes -q -c conda-forge "python~=${PYTHON_VERSION}=*_cpython" "numpy>=1.23.3" jax
pip install --no-deps -e ./

#Skipping these tests as per aesara's CI.

if ! python3 -m pytest -x -r A --verbose --runslow --cov=aesara/ --no-cov-on-fail --benchmark-skip --ignore=tests/link/numba --ignore=tests/test_printing.py --ignore=tests/compile/test_mode.py --ignore=tests/link/test_vm.py --ignore=tests/link/c/test_op.py --ignore=tests/tensor/nnet --ignore=tests/tensor/rewriting/test_shape.py --ignore=tests/tensor/signal ; then
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
