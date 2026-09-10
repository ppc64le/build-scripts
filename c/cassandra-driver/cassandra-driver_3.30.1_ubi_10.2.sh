#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cassandra-driver
# Version          : 3.30.1
# Source repo      : http://github.com/datastax/python-driver
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=cassandra-driver
PACKAGE_VERSION=${1:-3.30.1}
PACKAGE_URL=http://github.com/datastax/python-driver
PACKAGE_DIR=python-driver

# Install dependencies
dnf install -y \
    git \
    make \
    wget \
    sudo \
    openssl-devel \
    bzip2-devel \
    krb5-devel \
    libffi-devel \
    zlib-devel \
    python3.14 \
    python3.14-devel \
    python3.14-pip \
    cargo \
    rust

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

#Install libev
curl -LO https://dist.schmorp.de/libev/Attic/libev-4.33.tar.gz
tar -xzf libev-4.33.tar.gz
cd libev-4.33
export CFLAGS="-fPIC"
export LDFLAGS="-fPIC"
./configure --disable-shared --enable-static
make -j$(nproc)
make install
cd ..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

#install necessary Python packages
python3.14 -m pip install wheel pytest tox nox mock build gevent eventlet pyopenssl "setuptools<80" 
python3.14 -m pip install -r test-requirements.txt

export CASS_DRIVER_LIBEV_INCLUDES="/usr/local/include"
export CASS_DRIVER_LIBEV_LIBS="/usr/local/lib"
export LDFLAGS="-Wl,-Bstatic -lev -Wl,-Bdynamic"
python3.14 setup.py build_ext --inplace

#Install
if ! python3.14 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
#Skipping some tests as these are parity with intel and some test dependencies are deprecated with python3.11 and python3.14
if !(python3.14 -m pytest tests/unit/ \
    -k "not (CloudTests or TestTwistedConnection or _PoolTests or test_timeout_does_not_release_stream_id)" \
    --ignore=tests/unit/io/test_libevreactor.py \
    --ignore=tests/unit/io/test_asyncioreactor.py \
    --ignore=tests/unit/io/test_asyncorereactor.py \
    --ignore=tests/unit/cython/test_bytesio.py \
    --ignore=tests/unit/cython/test_types.py \
    --ignore=tests/unit/cython/test_utils.py -p no:warnings) ; then
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