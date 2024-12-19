#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hdbscan
# Version          : 0.8.33
# Source repo      : https://github.com/scikit-learn-contrib/hdbscan
# Tested on        : UBI:9.3
# Language         : Jupyter Notebook,Python
# Travis-Check     : True
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

PACKAGE_NAME=hdbscan
PACKAGE_VERSION=${1:-0.8.33}
PACKAGE_URL=https://github.com/scikit-learn-contrib/hdbscan

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "Installing dependencies..."
yum install -y git python3.11 python3.11-devel python3.11-pip wget gcc-c++ cmake pkgconfig gcc-gfortran libjpeg-devel libjpeg zlib-devel

#install openblas
echo "Downloading and installing openblas..."
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
echo "Starting make..."
make -j2
echo "Starting make install..."
make PREFIX=/usr/local/OpenBLAS install
echo "Completed make install..."
export PKG_CONFIG_PATH=/usr/local/OpenBLAS/lib/pkgconfig
cd ..

#install conda and activate env
echo "Downloading and installing miniconda..."
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda create -n hdbscan -y
conda init bash
eval "$(conda shell.bash hook)"
conda activate hdbscan

echo "Installing dependencies..."
conda install -q -y setuptools pip wheel build packaging numpy cython bzip2 hdf5 lzo

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python3 -m pip install --upgrade pip

echo "Installing dependencies..."
python3 -m pip install pytest pandas NetworkX matplotlib cython setuptools wheel

echo "Installing requirements.txt..."
pip3 install -r requirements.txt

echo "Installing..."
if ! python3 setup.py develop ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Testing..."
if ! pytest; then
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
