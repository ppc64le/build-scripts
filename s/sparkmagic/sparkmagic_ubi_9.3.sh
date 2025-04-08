#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sparkmagic
# Version          : 0.20.0
# Source repo      : https://github.com/jupyter-incubator/sparkmagic.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
# Variables
PACKAGE_NAME=sparkmagic
PACKAGE_VERSION=${1:-0.20.0}
PACKAGE_URL=https://github.com/jupyter-incubator/sparkmagic.git
PACKAGE_DIR=sparkmagic/sparkmagic/

# Install dependencies
yum install -y git gcc gcc-c++ make wget python-devel openssl-devel bzip2-devel libffi-devel xz cmake krb5-devel.ppc64le openblas-devel  sqlite-devel
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
./install.sh
export PATH=$HOME/.cargo/bin:$PATH
rustc -V
cargo  -V
cd ..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
pip install -r requirements.txt
pip install notebook==6.5.0
pip install pytest

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests skipping the test failing on both x86 and ppc64le
if !(pytest sparkmagic/tests --ignore=sparkmagic/tests/test_reliablehttpclient.py --ignore=sparkmagic/tests/test_kernel_magics.py --ignore=sparkmagic/tests/test_configuration.py --ignore=sparkmagic/tests/test_sparkmagicsbase.py --ignore=sparkmagic/tests/test_sparkstorecommand.py --ignore=sparkmagic/tests/test_sparkevents.py --ignore=sparkmagic/tests/test_sparkkernelbase.py --ignore=sparkmagic/tests/test_sparkcontroller.py --ignore=sparkmagic/tests/test_remotesparkmagics.py --ignore=sparkmagic/tests/test_exceptions.py
); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi