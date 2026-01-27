#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : pymssql
# Version       : v2.3.11
# Source repo   : https://github.com/pymssql/pymssql.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <Shivansh.s1@ibm.com>
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
PACKAGE_VERSION=${1:-v2.3.11}
PACKAGE_URL=https://github.com/pymssql/pymssql.git
PACKAGE_DIR=pymssql
CURRENT_DIR=`pwd`

# Install dependencies and tools.
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ python3.12 python3.12-pip python3.12-devel openssl-devel krb5-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Python dependencies
python3.12 -m pip install -r dev/requirements-dev.txt
python3.12 -m pip install cython
python3.12 -m pip install setuptools_scm>=5.0
python3.12 -m pip install wheel>=0.36.2

# Root Cause:
# - Python 2 had a separate `long` type, but Python 3 unified it into `int`.
# - Older pymssql versions (<=2.3.4) still reference `long`, which no longer exists.
# - From pymssql 2.3.5 onwards, the maintainers fixed this by replacing
#   all `long` references with `int`, making those versions compatible.

if [[ "$(printf '%s\n' "2.3.4" "${PACKAGE_VERSION#v}" | sort -V | head -n1)" == "${PACKAGE_VERSION#v}" ]]; then
    echo "Applying sed fixes for <=2.3.4..."
        sed -i 's/return long(/return int(/' src/pymssql/_mssql.pyx
        sed -i 's/(int, long, bytes)/(int, bytes)/' src/pymssql/_mssql.pyx
        sed -i 's/(int, long, decimal.Decimal)/(int, decimal.Decimal)/' src/pymssql/_mssql.pyx
fi
sed -i "s/{TDS_ENCRYPTION_LEVEL.keys())}/{list(TDS_ENCRYPTION_LEVEL.keys())}/" src/pymssql/_mssql.pyx
export SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#v}
BUILD_CMD="python3.12 dev/build.py \
    --ws-dir=./freetds \
    --dist-dir=./dist \
    --with-openssl=yes \
    --enable-krb5 \
    --sdist \
    --static-freetds"

# Append --wheel for versions > 2.3.4
if [[ "$(printf '%s\n' "2.3.4" "${PACKAGE_VERSION#v}" | sort -V | head -n1)" != "${PACKAGE_VERSION#v}" ]]; then
    BUILD_CMD+=" --wheel"
fi

# Run the command
eval "$BUILD_CMD"

#Build commands are explicitly in the script to apply version-specific fixes and ensure a reproducible, compatible wheel build across different pymssql versions and Python 3.12.
python3.12 -m pip install pymssql --no-index -f dist
python3.12 setup.py bdist_wheel

cp dist/*.whl ${CURRENT_DIR}

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
    exit 0
fi
