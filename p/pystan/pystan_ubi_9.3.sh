#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pystan
# Version          : 3.10.0
# Source repo      : https://github.com/stan-dev/pystan
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pystan
PACKAGE_VERSION=${1:-3.10.0}
PACKAGE_URL=https://github.com/stan-dev/pystan
CURRENT_DIR=$(pwd)

yum install -y git make wget gcc-toolset-13 openssl-devel python3.12 python3.12-pip python3.12-devel

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone and build CmdStan (for stanc)
cd $CURRENT_DIR
git clone https://github.com/stan-dev/cmdstan
cd cmdstan
git checkout v2.34.1
git submodule update --init --recursive
make build -j$(nproc)
export PATH=$CURRENT_DIR/cmdstan/bin:$PATH
which stanc
stanc --version

# Clone and build httpstan
cd $CURRENT_DIR
git clone https://github.com/stan-dev/httpstan
cd httpstan
cp $CURRENT_DIR/cmdstan/bin/stanc $CURRENT_DIR/httpstan/httpstan/stanc
chmod +x $CURRENT_DIR/httpstan/httpstan/stanc

PYTHON_VER=$(python3.12 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
export PYTHON_PATH=$(which python${PYTHON_VER})
ln -sf $PYTHON_PATH /usr/bin/python3

# Get Python include path
PYTHON_INCLUDE=$(python3.12 -c "from sysconfig import get_paths; print(get_paths()['include'])")
export CPLUS_INCLUDE_PATH=$PYTHON_INCLUDE:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=$PYTHON_INCLUDE:$C_INCLUDE_PATH

make 

python3.12 -m pip install --upgrade pip setuptools wheel pandas
python3.12 -m pip install poetry==1.7.1
poetry export -f requirements.txt --without-hashes --dev -o requirements.txt

python3.12 -m pip install -e .

cd $CURRENT_DIR

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

rm -f $CURRENT_DIR/httpstan/httpstan/stanc
cp $CURRENT_DIR/cmdstan/bin/stanc $CURRENT_DIR/httpstan/httpstan/stanc
chmod +x $CURRENT_DIR/httpstan/httpstan/stanc

python3.12 -m pip install -r $CURRENT_DIR/httpstan/requirements.txt
poetry build -v

if ! python3.12 -m pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
 
if ! pytest -s -v tests ; then
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
