#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : unicodedata2
# Version       : 16.0.0
# Source repo   : http://github.com/fonttools/unicodedata2
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=unicodedata2
PACKAGE_VERSION=${1:-16.0.0}
PACKAGE_URL=http://github.com/fonttools/unicodedata2
PACKAGE_DIR=unicodedata2

yum install -y git  python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo cmake
pip3 install pytest tox nox
PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

# Install rust
if [[ "$PACKAGE_URL" == *github.com* ]]; then
    # Use git clone if it's a Git repository
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
            echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
            exit 1
        fi
        cd "$PACKAGE_DIR" || exit
        git checkout "$PACKAGE_VERSION" || exit
    fi
fi

# Install via pip3
if !  python3 -m pip install ./; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
        exit 1
fi

# Run Tox
PYTHON_VERSION=$(python3 -c "import sys; print(f'py{sys.version_info.major}{sys.version_info.minor}')")
echo "Detected Python version for tox: $PYTHON_VERSION"

python3 -m tox -e "$PYTHON_VERSION"

if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
fi
