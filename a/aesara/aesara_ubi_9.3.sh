#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : aesara
# Version       : rel-2.9.4
# Source repo   : https://github.com/aesara-devs/aesara
# Tested on     : UBI: 9.3
# Language      : javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=aesara
PACKAGE_VERSION=${1:-rel-2.9.4}
PACKAGE_URL=https://github.com/aesara-devs/aesara

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y wget yum-utils

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm


yum install -y wget git gcc gcc-c++ python3 python3-devel llvm14 llvm14-devel llvm14-static clang openblas openblas-devel gcc-gfortran blas blas-devel
export PATH=$PATH:/usr/lib64/llvm14/bin
export LLVM_CONFIG=$(which llvm-config)
which llvm-config
python3 -m pip install llvmlite requests==2.26.0 wheel tox pytest numpy typing_extensions scipy cons etuples llvmlite kanren numba

git clone https://github.com/pythological/unification.git
cd unification
pip install -e .
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.9/site-packages
export PYTHONPATH=$PYTHONPATH:/unification
pip show unification
python3 -c "import unification; print(unification.__file__)"

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! pip3 install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Skipping these tests as per aesara's CI.

if ! python3 -m pytest --ignore=tests/link/numba --ignore=tests/test_printing.py --ignore=tests/compile/test_mode.py --ignore=tests/link/test_vm.py --ignore=tests/link/c/test_op.py --ignore=tests/tensor/nnet --ignore=tests/tensor/rewriting/test_shape.py --ignore=tests/tensor/signal --ignore=tests/tensor/random --ignore=tests/scan/ ; then
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

