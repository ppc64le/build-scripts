#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ruamel.yaml.clib
# Version          : 0.2.6
# Source repo      : https://pypi.io/packages/source/r/ruamel.yaml.clib/ruamel.yaml.clib-0.2.6.tar.gz
# Tested on	: UBI:9.3
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

PACKAGE_NAME=ruamel.yaml.clib
PACKAGE_VERSION=${1:-0.2.6}
PACKAGE_URL=https://pypi.io/packages/source/r/ruamel.yaml.clib/ruamel.yaml.clib-0.2.6.tar.gz
PACKAGE_DIR="$(pwd)/$PACKAGE_NAME"

yum install -y git  python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo
pip3 install pytest tox nox
PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

if [[ "$PACKAGE_URL" == *github.com* ]]; then
        # Use git clone if it's a Git repository
        if [ -d "$PACKAGE_NAME" ]; then
            cd "$PACKAGE_NAME" || exit
        else
            if ! git clone "$PACKAGE_URL" "$PACKAGE_NAME"; then
                echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"  
                exit 1
            fi
            cd "$PACKAGE_NAME" || exit
            git checkout "$PACKAGE_VERSION" || exit
        fi
else
        # If it's not a Git repository, download and untar
        if [ -d "$PACKAGE_NAME" ]; then
            cd "$PACKAGE_NAME" || exit
        else
            # Use download and untar if it's not a Git repository
            if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_NAME.tar.gz"; then
                echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Download_Fails"  
                exit 1
            fi
            mkdir "$PACKAGE_NAME"
            # Extract the downloaded tarball
            if ! tar -xzf "$PACKAGE_NAME.tar.gz" -C "$PACKAGE_NAME" --strip-components=1; then
                echo "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Untar_Fails"  
                exit 1
            fi

            cd "$PACKAGE_NAME" || exit
        fi
fi

# Install via pip3
if !  python3 -m pip install ./; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

if [ -f tox.ini ]; then
    if !  python3 -m tox -e py39; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"  
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success" 
        exit 0
    fi
elif [ -f noxfile.py ]; then
    if !  python3 -m nox; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"  
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"   
        exit 0
    fi
else
    if ! python3 -m pytest; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"  
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"   
        exit 0
    fi
fi
