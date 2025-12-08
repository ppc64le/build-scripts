#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : persistent
# Version       : 5.1
# Source repo   : https://github.com/zopefoundation/persistent
# Tested on     : UBI 8.7
# Language      : python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=persistent
PACKAGE_VERSION=${1:-5.1}
PACKAGE_URL=https://github.com/zopefoundation/persistent


yum install -y git python39 python39-devel gcc gcc-c++ make
pip3 install pytest tox
PATH=$PATH:/usr/local/bin/

# Clone the repository
git clone $PACKAGE_URL $PACKAGE_NAME

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install dependencies from requirements.txt

REQUIREMENTS_PRESENT=(`find . -print | grep -i requirements.txt`)

for i in "${REQUIREMENTS_PRESENT[@]}"; do
        echo "Installing using pip from file:"
        echo $i
        pip3  install -r $i
done

#check if setup.py file is present
if [ -f "setup.py" ];then
        if ! python3 setup.py install ; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
        fi
        echo "setup.py file exists"
else
        echo "setup.py not present"
fi


#check if tox file is present
if [ -f "tox.ini" ];then
        echo "tox.ini file exists"
        if ! tox -e py39 ; then
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
else
        echo "tox.ini not present"
        if ! pytest ; then
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

fi
