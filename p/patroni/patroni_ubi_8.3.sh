# ----------------------------------------------------------------------------
#
# Package               : patroni
# Version               : 2.1.1
# Source repo           : https://github.com/zalando/patroni
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Note                  : working only for py39 ,test failing in py36 & py38 
# Script License        : Apache License, Version 2 or later
# Maintainer            : Priya Seth<sethp@us.ibm.com> Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

PACKAGE_NAME="patroni"
PACKAGE_VERSION=${1:-"v2.1.1"}
export PACKAGE_URL=${PACKAGE_URL:-"https://github.com/zalando/patroni"}
export PYVERSION=${PYVERSION:-"39"}
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#cleaning up the package installation
if [ $1 = "clean" ]; then
    rm -rf ~/patroni*
    sudo dnf remove  python$PYVERSION python$PYVERSION-devel  rust cargo libffi-devel openssl-devel -y
    exit 0
fi

# Dependency installation
sudo dnf install python$PYVERSION-devel  rust cargo libffi-devel openssl-devel -y


# clone the repo
git clone $PACKAGE_URL $PACKAGE_NAME || exit 1

# Build and Test patroni
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION || exit 1
echo "$PACKAGE_VERSION found to checkout "
# building and testing package in virtual environment

#creating virtualenv
echo "creating virtual environment  at ~/${PACKAGE_NAME}_venv_PY${PYVERSION}"
python3 -m venv ~/${PACKAGE_NAME}_venv_PY${PYVERSION}
source  ~/${PACKAGE_NAME}_venv_PY${PYVERSION}/bin/activate
#Installing dependencies
pip install --upgrade pip
pip install Cython wheel
pip install -r requirements.txt
pip install -r requirements.dev.txt
python .github/workflows/install_deps.py

#installing PKG
if ! pip install -e .  ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
# building python wheel
python setup.py bdist_wheel
#Run tests and flake8

if ! python3 .github/workflows/run_tests.py    ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi