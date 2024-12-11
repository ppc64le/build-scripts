#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dask
# Version          : 2.20.0
# Source repo      : https://github.com/dask/dask.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith B R <rakshith.r5@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=dask
PACKAGE_VERSION=${1:-2.20.0}  # Default version set to 2.20.0
PACKAGE_URL=https://github.com/dask/dask.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget python3-devel python3-pip libyaml-devel
yum groupinstall -y "Development Tools"

# Upgrade pip and install setuptools, wheel
pip install --upgrade pip setuptools wheel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Install Dask
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

#Install pytest
pip install pytest
pip install --upgrade pip setuptools wheel
pip install packaging --no-binary :all:
pip install pandas==1.5.3
pip install numpy==1.23.0
pip install cachey --no-binary :all:
pip install distributed --no-binary :all:
pip install graphviz --no-binary :all:
pip install psutil --no-binary :all:

sed -i '84s/if (cloudpickle.__version__) < Version("1.3.0")/if (cloudpickle.__version__) < str(Version("1.3.0"))/' dask/tests/test_multiprocessing.py
sed -i '107s/for name, col in df.iteritems()/for name, col in df.items()/g' dask/sizeof.py
sed -i 's/@implements(np.round, np.round_)/@implements(np.round)/' dask/array/routines.py
sed -i 's/from distutils.version import LooseVersion/from packaging.version import Version/' dask/compatibility.py
sed -i 's/LooseVersion/Version/' dask/compatibility.py

#Run tests
cd dask/tests
if ! pytest -p no:warnings --ignore=test_base.py --ignore=test_config.py; then
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
