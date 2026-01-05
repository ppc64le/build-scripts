#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		 : sparqlwrapper
# Version		 : 2.0.0
# Source repo	         : https://github.com/RDFLib/sparqlwrapper
# Tested on		 : UBI:9.3
# Language      	 : Python
# Ci-Check  	 : True
# Script License	 : Apache License, Version 2 or later
# Maintainer		 : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer		 : This script has been tested in root mode on given
# ==========  		   platform using the mentioned version of the package.
#             	           It may not work as expected with newer versions of the
#             	           package and/or distribution. In such case, please
#                          contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=sparqlwrapper
PACKAGE_VERSION=${1:-2.0.0} 
PACKAGE_URL=https://github.com/RDFLib/sparqlwrapper

yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo

#install rust
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
sudo ./install.sh
export PATH=$HOME/.cargo/bin:$PATH
rustc -V
cargo  -V
cd ../

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install -U pip

if ! pip install '.[dev]'; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3 -m unittest test/test_wrapper.py -v; then
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
