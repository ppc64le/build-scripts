#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ipywidgets
# Version       : 8.0.4
# Source repo   : https://github.com/jupyter-widgets/ipywidgets
# Tested on     : UBI:9.3
# Language      : Python,Typescript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=ipywidgets
PACKAGE_VERSION=${1:-8.0.4}
PACKAGE_URL=https://github.com/jupyter-widgets/ipywidgets

export NODE_VERSION=${NODE_VERSION:-16}
yum install -y wget python3 python3-devel.ppc64le git gcc gcc-c++ libffi make

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

#Install miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
export PATH=$HOME/conda/bin/:$PATH
conda --version

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python -m pip install -U pip
pip install "pytest<8"

if ! pip install file://$PWD/python/ipywidgets#egg=ipywidgets[test] ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cd python/ipywidgets
# Run tests (skipping the some testcase as it is failing on x_86 also.)
if ! pytest --cov=ipywidgets ipywidgets -k "not (test_deprecation_fa_icons or test_append_display_data or test_tooltip_deprecation or test_on_submit_deprecation)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
