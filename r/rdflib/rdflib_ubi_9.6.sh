#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rdflib
# Version          : 7.1.4
# Source repo      : https://github.com/RDFLib/rdflib
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
set -ex

# Variables
PACKAGE_NAME=rdflib
PACKAGE_VERSION=${1:-7.1.4 }
PACKAGE_URL=https://github.com/RDFLib/rdflib
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y git make wget gcc-toolset-13 openssl-devel python3 python3-pip python3-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install python dependencies
pip install -r devtools/requirements-poetry.in
pip install pytest setuptools

#install
if ! pip install  . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
# Skipping test, community suggested theses steps to skip reference : https://github.com/RDFLib/rdflib/issues/2649 and https://github.com/RDFLib/rdflib/issues/1519
#Also because the test depends on an external HTTP server that now returns 406 Not Acceptable, causing nondeterministic failures.
if ! pytest -k "not sparql and not service and not test_parser and not test_guess_format_for_parse_http_text_plain" ; then
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
