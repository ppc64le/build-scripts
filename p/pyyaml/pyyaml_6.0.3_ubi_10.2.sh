#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyyaml
# Version       : 6.0.3
# Source repo   : https://github.com/yaml/pyyaml
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyyaml
PACKAGE_VERSION=${1:-"6.0.3"}
PACKAGE_URL=https://github.com/yaml/pyyaml.git

yum install -y git python3.14 python3.14-devel libyaml-devel gcc gcc-c++

python3.14 -m ensurepip --upgrade
python3.14 -m pip install --upgrade pip setuptools wheel

# ----- Choose correct Cython automatically -----
PYVER=$(python3.14 - << 'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
if [[ "$PYVER" == "3.13" || "$PYVER" == "3.14" ]]; then
    python3.14 -m pip install "cython>=3.0" wheel pytest
else
    python3.14 -m pip install "cython<3.0.0" wheel pytest
fi


PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build wheel
if ! python3.14 -m pip wheel . --no-deps -w dist ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Install the generated wheel
if ! python3.14 -m pip install --force-reinstall dist/*.whl ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests
if ! pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_Install_&_Test_success----------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_Install_and_Test_Success"
    exit 0
fi