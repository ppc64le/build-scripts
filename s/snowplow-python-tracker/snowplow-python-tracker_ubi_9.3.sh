#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : snowplow-python-tracker
# Version       : 1.0.2
# Source repo   : https://github.com/snowplow/snowplow-python-tracker
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=snowplow-python-tracker
PACKAGE_VERSION=${1:-'1.0.2'}
PACKAGE_URL=https://github.com/snowplow/snowplow-python-tracker

yum install wget -y
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/

yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ patch openssl openssl-devel zlib zlib-devel bzip2 bzip2-devel sqlite sqlite-devel xz xz-devel ncurses ncurses-devel readline readline-devel libtiff libtiff-devel libffi-devel
PATH=$PATH:/usr/local/bin/

# Install & configure pyenv
curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
 
# Installing required Python versions
pyenv install 3.6.14
pyenv install 3.7.11
pyenv install 3.8.11
pyenv install 3.9.6
pyenv install 3.10.1
pyenv install 3.11.0
pyenv install 3.12.0

pyenv global 3.6.14 3.7.11 3.8.11 3.9.6 3.10.1 3.11.0 3.12.0

rm -rf snowplow-python-tracker
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Supress deprecation warnings
sed -i '7i export PYTHONWARNINGS="ignore::DeprecationWarning"' run-tests.sh

# Package syntax is not compatible with Python 3.5 anymore so skipping the v3.5 tests
sed -i '20,26s/^/# /; 94,96s/^/# /' run-tests.sh


if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test env setup
./run-tests.sh deploy

if ! ./run-tests.sh test ; then
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
