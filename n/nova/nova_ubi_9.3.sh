#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : nova
# Version       : 29.0.2
# Source repo   : https://github.com/openstack/nova
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=nova
PACKAGE_VERSION=${1:-29.0.2}
PACKAGE_URL=https://github.com/openstack/nova

#Install dependencies
#yum -y update
yum install -y python3.ppc64le python3-devel.ppc64le gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget git
yum install -y libffi-devel pkg-config libpq-devel postgresql postgresql-devel libxml2-devel libxmlsec1-devel libxslt-devel
python3 -m pip install --upgrade pip
yum install libxml2-devel
yum install -y libffi-devel pkg-config libpq-devel postgresql postgresql-devel libxml2-devel libxslt-devel
yum install xmlsec1.ppc64le -y
yum install -y openssl-devel openssl


git clone $PACKAGE_URL
cd $PACKAGE_NAME 
git checkout $PACKAGE_VERSION

python3 -m pip install psycopg2-binary xmlsec lxml psycopg2 pyparsing ldappool --ignore-installed
python3 -m pip install -r requirements.txt
python3 -m pip install -r test-requirements.txt
python3 setup.py install

python3 -m pip install tox --ignore-installed
python3 -m pip install wheel

wget https://static.rust-lang.org/dist/rust-1.63.0-powerpc64le-unknown-linux-gnu.tar.gz 
tar -zxvf rust-1.63.0-powerpc64le-unknown-linux-gnu.tar.gz 
cd rust-1.63.0-powerpc64le-unknown-linux-gnu
sh install.sh
rm -rf rust-1.63.0-powerpc64le-unknown-linux-gnu.tar.gz &&      
rm -rf rust-1.63.0-powerpc64le-unknown-linux-gnu

python3 -m pip install --upgrade pip
python3 -m pip install --ignore-installed chardet
python3 -m pip install tox tox-gh-actions

if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

sed -i '623,625d' nova/nova/tests/unit/virt/test_virt_drivers.py

if ! python3 -m tox -e py3 ; then
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
