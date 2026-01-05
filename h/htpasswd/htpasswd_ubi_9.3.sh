#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: htpasswd
# Version	: 2.3
# Source repo	: https://github.com/thesharp/htpasswd
# Tested on	: UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=htpasswd
PACKAGE_VERSION=${1:-2.3}
PACKAGE_URL=https://github.com/thesharp/htpasswd
PACKAGE_DIR=htpasswd

yum install -y git python3.11 python3.11-devel python3.11-pip gcc gcc-c++ make wget sudo cmake
PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

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
        git checkout master || exit
    fi
fi

# Install via pip3
if !  python3.11 -m pip install ./; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# build wheel
python3.11 -m pip install wheel

if ! python3.11 -m pip wheel --no-deps htpasswd==${PACKAGE_VERSION}; then
    echo "--------------------$PACKAGE_NAME:wheel_build_fails----------------------------------------"
    exit 2
else
    echo "--------------------$PACKAGE_NAME:wheel_build_success----------------------------------------"
fi

exit 0
