#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pystan
# Version          : 3.10.0
# Source repo      : https://github.com/stan-dev/pystan
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K<Vinod.K1@ibm.com>
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

yum install -y git make wget gcc-toolset-13 openssl-devel python3 python3-devel python3-pip

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
PYTHON_BIN=$(which python3)
PIP_BIN=$(which pip3)

# Clone and build CmdStan
cd "$CURRENT_DIR"
git clone https://github.com/stan-dev/cmdstan
cd cmdstan
git checkout v2.34.1
git submodule update --init --recursive
make build -j"$(nproc)"
export PATH=$CURRENT_DIR/cmdstan/bin:$PATH
which stanc
stanc --version

# Clone and build httpstan
cd "$CURRENT_DIR"
git clone https://github.com/stan-dev/httpstan
cd httpstan
cp "$CURRENT_DIR/cmdstan/bin/stanc" "$CURRENT_DIR/httpstan/httpstan/stanc"
chmod +x "$CURRENT_DIR/httpstan/httpstan/stanc"

$PYTHON_BIN -m pip install --upgrade pip setuptools wheel pandas
$PYTHON_BIN -m pip install poetry==1.7.1

poetry export -f requirements.txt --without-hashes --dev -o requirements.txt

PYTHON_INCLUDE="$($PYTHON_BIN -c 'import sysconfig; print(sysconfig.get_path("include"))')"
PYTHON_PLATINCLUDE="$($PYTHON_BIN -c 'import sysconfig; print(sysconfig.get_path("platinclude"))')"
PYTHON_CFLAGS="$($PYTHON_BIN -c 'import sysconfig; print(" ".join(sysconfig.get_config_vars("CFLAGS")))')"
PYTHON_CCSHARED="$($PYTHON_BIN -c 'import sysconfig; print(" ".join(sysconfig.get_config_vars("CCSHARED")))')"

make \
  PYTHON_INCLUDE="-I$PYTHON_INCLUDE" \
  PYTHON_PLATINCLUDE="-I$PYTHON_PLATINCLUDE" \
  PYTHON_CFLAGS="$PYTHON_CFLAGS" \
  PYTHON_CCSHARED="$PYTHON_CCSHARED"

$PYTHON_BIN -m pip install -e .

cd "$CURRENT_DIR"

# Clone and install pystan
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

$PYTHON_BIN -m pip install -r "$CURRENT_DIR/httpstan/requirements.txt"
poetry build -v

if ! $PIP_BIN install -e .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

rm -f "$CURRENT_DIR/httpstan/httpstan/stanc"
cp "$CURRENT_DIR/cmdstan/bin/stanc" "$CURRENT_DIR/httpstan/httpstan/stanc"
chmod +x "$CURRENT_DIR/httpstan/httpstan/stanc"

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
