#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pykrb5
# Version          : v0.10.0
# Source repo      : https://github.com/jborean93/pykrb5.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pykrb5
PACKAGE_VERSION=${1:-v0.10.0}
PACKAGE_URL=https://github.com/jborean93/pykrb5.git

# Install dependencies and tools
yum install -y git wget gcc gcc-c++ make python3.12 python3.12-devel python3.12-pip krb5-devel krb5-libs

# KDC libs and tools for tests (all in UBI)
yum install -y krb5-workstation krb5-pkinit libkadm5 libverto libss lmdb-libs keyutils-libs

# krb5-server and libverto-libev (event loop for krb5kdc) are not in UBI, so use AlmaLinux
ALMA=https://repo.almalinux.org/almalinux/9/BaseOS/ppc64le/os/Packages
rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-9
rpm -ivh --nodeps $ALMA/krb5-server-1.21.1-10.el9_8.1.ppc64le.rpm $ALMA/libev-4.33-6.el9.ppc64le.rpm $ALMA/libverto-libev-0.3.2-3.el9.ppc64le.rpm

# Fail early if KDC binaries or their libs are missing
for b in /usr/sbin/kdb5_util /usr/sbin/krb5kdc /usr/sbin/kadmind /usr/sbin/kadmin.local /usr/bin/kinit; do
    [ -x "$b" ] || { echo "Missing $b"; exit 1; }
    if ldd "$b" | grep "not found"; then echo "Missing libs for $b"; exit 1; fi
done
[ -f /usr/lib64/libverto-libev.so.1 ] || { echo "Missing libverto-libev"; exit 1; }

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.12 -m pip install --upgrade pip
python3.12 -m pip install pytest wheel build "k5test>=0.10.4"

# Build and install (Cython is pinned in pyproject.toml build requirements)
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Build the wheel
python3.12 -m build --wheel

# Run tests
if ! python3.12 -m pytest -v ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
