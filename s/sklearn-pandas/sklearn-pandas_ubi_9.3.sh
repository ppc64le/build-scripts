#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : sklearn-pandas
# Version       : v2.2.0
# Source repo   : https://github.com/scikit-learn-contrib/sklearn-pandas.git
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
PACKAGE_NAME=sklearn-pandas
PACKAGE_VERSION=${1:- v2.2.0}
PACKAGE_URL=https://github.com/scikit-learn-contrib/sklearn-pandas.git

# Install dependencies and tools.
yum install -y gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel cmake zlib-devel libjpeg-devel wget

dnf install 'dnf-command(config-manager)' -y && \
        yum config-manager  --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os && \
        yum config-manager  --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
        wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
        mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official && \
        yum install -y openblas-devel

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing dependencies
pip install scipy scikit-learn pandas

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
