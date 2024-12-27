#!/bin/bash -e
    # ----------------------------------------------------------------------------
    # 
    # Package       : bottleneck
    # Version       : v1.3.5
    # Source repo   : https://github.com/pydata/bottleneck.git
    # Tested on     : UBI:9.3
    # Language      : Python
    # Travis-Check  : True
    # Script License: Apache License, Version 2 or later
    # Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
    #
    # Disclaimer: This script has been tested in root mode on given
    # ==========  platform using the mentioned version of the package.
    #             It may not work as expected with newer versions of the
    #             package and/or distribution. In such case, please
    #             contact "Maintainer" of this script.
    #
    # ----------------------------------------------------------------------------
    
    #variables
    PACKAGE_NAME=bottleneck
    PACKAGE_VERSION=${1:-v1.3.5}
    PACKAGE_URL=https://github.com/pydata/bottleneck.git
    
    # Install dependencies and tools.
    yum install -y wget gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel 
    
    #clone repository 
    git clone $PACKAGE_URL
    cd  $PACKAGE_NAME
    git checkout $PACKAGE_VERSION
    
    #install
    if ! (pip install .) ; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
    fi
    
    pip install chardet --upgrade
    pip install requests --upgrade
    pip install tox
    
    #test
    if ! tox -e py39; then
        echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
    else
        echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
    fi
