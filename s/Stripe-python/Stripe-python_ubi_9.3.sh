#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : stripe-python
# Version          : v10.5.0
# Source repo      : https://github.com/stripe/stripe-python.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=stripe-python
PACKAGE_VERSION=${1:-v10.5.0}
PACKAGE_URL=https://github.com/stripe/stripe-python.git

#install dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel

#install rust
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
./install.sh
export PATH=$HOME/.cargo/bin:$PATH
rustc -V
cargo  -V
cd ../

#install python3.10
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
tar xzf Python-3.10.0.tgz
cd Python-3.10.0
./configure --enable-optimizations
make -j 4
make altinstall
export PATH=$PATH:/usr/local/bin
cd ../

python3.10 -m venv stripe-venv
source stripe-venv/bin/activate

# Clone the repository
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.10 -m pip install pip wheel
python3.10 -m pip install pytest tox
python3.10 -m pip install -r requirements.txt
python3.10 -m pip install -r test-requirements.txt


#install
if ! python3.10 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! python3.10 -m pytest --nomock -k "not test_invoice.py and not test_invoice_line_item.py"; then
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

