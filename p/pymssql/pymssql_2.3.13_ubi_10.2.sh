#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pymssql
# Version          : 2.3.13
# Source repo      : https://github.com/pymssql/pymssql.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Yogita Kulkarni <Yogita.Kulkarni@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=pymssql
PACKAGE_VERSION=${1:-2.3.13}
PACKAGE_URL=https://github.com/pymssql/pymssql.git
PACKAGE_DIR=pymssql
CURRENT_DIR=$(pwd)

# Install system dependencies.
# Python packages must come first (wrapper strips them for venv re-installs).
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    openssl-devel krb5-devel

# UBI 10 dropped SCL — activate gcc-toolset-15 via PATH export.
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Export CC/CXX so FreeTDS ./configure finds the toolset compiler.
export CC=$(which gcc)
export CXX=$(which g++)

# Upgrade pip and install build tools.
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install cython "setuptools_scm>=5.0"

# Clone and checkout.
cd "$CURRENT_DIR"
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Install only the build-time requirements needed to compile the extension.
# Do NOT install dev/requirements-dev.txt — it pulls in Sphinx and sphinxcontrib
# packages that drop Python 3.7-era .pth files into site-packages, which corrupts
# stdlib imports (json, traceback) under Python 3.14 and breaks the pip wheel
# subprocess with "ModuleNotFoundError: No module named 'json'".
python3.14 -m pip install \
    "cython>=3.1.0" \
    "setuptools>=80.0" \
    "setuptools_scm[toml]>=5.0,<10.0" \
    "wheel>=0.36.2" \
    "packaging>=24.2" \
    "standard-distutils"

# Apply version-specific source fixes.
# pymssql <= 2.3.4 still references the Python 2 `long` type.
if [[ "$(printf '%s\n' "2.3.4" "${PACKAGE_VERSION#v}" | sort -V | head -n1)" == "${PACKAGE_VERSION#v}" ]]; then
    echo "Applying fixes for pymssql <= 2.3.4 ..."
    sed -i 's/return long(/return int(/' src/pymssql/_mssql.pyx
    sed -i 's/(int, long, bytes)/(int, bytes)/' src/pymssql/_mssql.pyx
    sed -i 's/(int, long, decimal.Decimal)/(int, decimal.Decimal)/' src/pymssql/_mssql.pyx
fi

sed -i "s/{TDS_ENCRYPTION_LEVEL.keys())}/{list(TDS_ENCRYPTION_LEVEL.keys())}/" src/pymssql/_mssql.pyx

export SETUPTOOLS_SCM_PRETEND_VERSION="${PACKAGE_VERSION#v}"

# Build FreeTDS from source and produce the pymssql wheel.
# dev/build.py --wheel builds FreeTDS statically and then builds the wheel.
if ! python3.14 dev/build.py \
        --ws-dir=./freetds \
        --dist-dir=./dist \
        --with-openssl=yes \
        --enable-krb5 \
        --sdist \
        --static-freetds \
        --wheel; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install from the wheel produced by dev/build.py (not from source rebuild).
python3.14 -m pip install pymssql --no-index -f dist

# Copy wheel to CURRENT_DIR for the CI wrapper / auditwheel.
cp dist/*.whl "$CURRENT_DIR/"

# Verify installation.
if ! python3.14 -c "import pymssql; print(pymssql.version_info())"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# pymssql's test suite requires a live SQL Server — not available in CI.
# Validate with an import + version smoke test instead.
if ! python3.14 -c "
import pymssql
import _mssql
info = pymssql.__version__
assert info == '2.3.13', f'Unexpected version: {info}'
print('pymssql version  :', pymssql.__version__)
print('freetds version  :', _mssql.get_dbversion())
print('import smoke test: PASS')
"; then
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
