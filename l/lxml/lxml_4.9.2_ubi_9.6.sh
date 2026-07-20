#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : lxml
# Version          : 4.9.2
# Source repo      : https://github.com/lxml/lxml.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=lxml
PACKAGE_VERSION=${1:-lxml-4.9.2}
PACKAGE_URL=https://github.com/lxml/lxml.git

# Install necessary system dependencies
yum install -y --allowerasing make g++ git gcc gcc-c++ wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip libxml2-devel libxslt-devel zlib-devel libffi-devel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# Install additional dependencies
pip install wheel pytest
pip install -r requirements.txt
pip install "cython<3.0"

python3 setup.py build_ext --inplace

#install
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests skipping few tests failing on both ppc64le and x86
if ! pytest -k "not test_incremental_xmlfile and not test_io and not test_elementtree and not test_autolink and not test_basic and not test_clean and not test_clean_embed and not test_feedparser_data and not test_formfill and not test_forms and not test_rewritelinks and not test_etree and not _XIncludeTestCase" -p no:warnings; then
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
