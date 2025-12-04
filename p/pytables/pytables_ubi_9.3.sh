#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : PyTables
# Version          : v3.9.2
# Source repo      : https://github.com/PyTables/PyTables
# Tested on        : UBI:9.3
# Language         : Python,Cython
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=PyTables
PACKAGE_VERSION=${1:-v3.9.2}
PACKAGE_URL=https://github.com/PyTables/PyTables

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git python3.11 python3.11-devel gcc-c++ cmake make pkgconfig gcc-gfortran python3.11-pip wget

#install openblas
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
make -j8
make PREFIX=/usr/local/OpenBLAS install
export PKG_CONFIG_PATH=/usr/local/OpenBLAS/lib/pkgconfig
cd ..

#install conda and activate env
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda create -n myenv -y
conda init bash
eval "$(conda shell.bash hook)"
conda activate myenv

conda install -q -y setuptools pip wheel build packaging numpy cython bzip2 hdf5 lzo

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install -r requirements.txt
python3 -m pip install --extra-index-url https://pypi.anaconda.org/scientific-python-nightly-wheels/simple 'numpy'

if ! python3 -m pip install -v tables ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! cd .. && python3 -m tables.tests.test_all; then
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
