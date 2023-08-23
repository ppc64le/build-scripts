#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyhdf
# Version          : v0.11.3
# Source repo      : https://github.com/fhs/pyhdf
# Tested on        : UBI 8.7
# Language         : C,Python
# Travis-Check     : True
# Script License   : MIT license
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyhdf
PACKAGE_VERSION=${1:-v0.11.3}
PACKAGE_URL=https://github.com/fhs/pyhdf

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git make wget gcc-c++ python38 gcc

#Install miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
export PATH=$HOME/conda/bin/:$PATH
conda --version

cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Install dependencies
python -m pip install -U pip

if ! python -m pip install numpy pytest ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi
conda install -y hdf4
pytest
if !  python examples/runall.py ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi

