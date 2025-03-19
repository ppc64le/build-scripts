#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : pymssql
# Version       : v2.3.2
# Source repo   : https://github.com/pymssql/pymssql.git
# Tested on     : UBI:9.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=pymssql
PACKAGE_VERSION=${1:-v2.3.2}
PACKAGE_URL=https://github.com/pymssql/pymssql.git

# Install dependencies and tools.
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install -y git gcc gcc-c++ python3.12 python3.12-pip python3.12-devel openssl-devel krb5-devel

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Python dependencies
python3.12 -m pip install -r dev/requirements-dev.txt
python3.12 -m pip install cython
python3.12 -m pip install setuptools_scm>=5.0
python3.12 -m pip install wheel>=0.36.2

python3.12 dev/build.py \
            --ws-dir=./freetds \
            --dist-dir=./dist \
            --with-openssl=yes \
            --enable-krb5 \
            --sdist \
            --static-freetds
python3.12 -m pip install pymssql --no-index -f dist
python3.12 setup.py bdist_wheel

#install
if ! ( python3.12 -c "import pymssql; print(pymssql.version_info())" ) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest -sv --durations=0; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    # copying wheel to the root location 
    cp ./dist/*.whl /
    exit 0
fi
