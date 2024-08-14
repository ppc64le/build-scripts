#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ansible
# Version       : v2.17.2
# Source repo   : https://github.com/ansible/ansible
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
PACKAGE_NAME=ansible
PACKAGE_VERSION=${1:-'v2.17.2'}
PACKAGE_URL=https://github.com/ansible/ansible

yum install wget -y
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/

yum install -y git make gcc gcc-c++ sudo yum-utils openldap-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libjpeg-devel openssl openssl-devel postgresql-devel gcc gcc-c++ libicu lz4 make bzip2-devel zlib-devel readline-devel ncurses-devel sqlite-devel man-db

#anisble-tests need python>=3.10
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz 
tar xzf Python-3.10.0.tgz
cd Python-3.10.0
./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
make -j ${nproc}
make altinstall
export PATH=$PATH:/usr/local/bin
cd .. && rm Python-3.10.0.tgz
python3.10 -V

#Install Rust
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
sudo ./install.sh
export PATH=$HOME/.cargo/bin:$PATH
rustc -V
cargo  -V
cd ../

python3.10 -m pip install --upgrade pip wheel setuptools pytest ansible pexpect botocore pytest-mock pytest-xdist passlib
rm -rf ansible/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install -r requirements.txt

if ! python3.10 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

source ./hacking/env-setup
sudo ln -sf /usr/local/bin/python3.10 /usr/bin/python
cd /usr/bin
rm -rf python3 python3.9
cd /
cd $PACKAGE_NAME

if ! ansible-test units ; then
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