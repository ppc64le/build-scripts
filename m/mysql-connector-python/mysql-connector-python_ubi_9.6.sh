#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mysql-connector-python
# Version       : 26.7.0
# Source repo   : https://github.com/mysql/mysql-connector-python
# Tested on     : UBI 9.6
# Language      : Python
# Ci-Check      : True
# Script License: GNU General Public License (GPLv2)
# Maintainer    : Vrusha.Naik <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mysql-connector-python
PACKAGE_VERSION=${1:-9.7.0}
PACKAGE_URL=https://github.com/mysql/mysql-connector-python
# PACKAGE_DIR is relative to CURRENT_DIR (the wrapper's starting directory).
# The clone is done from CURRENT_DIR so this path is always valid.
PACKAGE_DIR=mysql-connector-python/mysql-connector-python

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system build dependencies. cmake + ncurses-devel are needed to build MySQL 8.0 client library from source. MySQL does not publish ppc64le RPMs; we build libmysqlclient ourselves.
yum install -y git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ python3 python3-devel python3-pip make cmake openssl openssl-devel ncurses-devel wget sudo

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Build MySQL 8.4 client library from source: 
# MySQL does not publish ppc64le RPMs or binary tarballs. We clone the MySQL 8.4.4 source and do a client-only cmake build (-DWITHOUT_SERVER=ON) to obtain libmysqlclient.so and MySQL 8.x C API headers. This is the only source of MYSQL_OPT_SSL_MODE, SSL_MODE_VERIFY_IDENTITY, MYSQL_OPT_USER_PASSWORD, mysql_real_escape_string_quote etc. that mysql-connector-python 9.7.0's C extension requires.
#
# Why 8.4 over 8.0:
#   - MySQL 8.4 bundles libtirpc (extra/tirpc) via -DWITH_TIRPC=bundled,
#     so no system libtirpc-devel is needed (unavailable in UBI 9 ppc64le).
#   - MySQL 8.0 requires system libtirpc-devel even for client-only builds.
#   - MySQL 8.4 requires Boost 1.84 (auto-downloaded via -DDOWNLOAD_BOOST=1).

MYSQL_SRC_VERSION=8.4.4
MYSQL_SRC_TAG=mysql-${MYSQL_SRC_VERSION}
MYSQL_SRC_DIR=/tmp/mysql-server-${MYSQL_SRC_VERSION}
MYSQL_CAPI_PREFIX=/usr/local/mysql-capi

if [ ! -f "${MYSQL_CAPI_PREFIX}/bin/mysql_config" ]; then
    if [ ! -d "$MYSQL_SRC_DIR" ]; then
        git clone --depth=1 --branch "$MYSQL_SRC_TAG" \
            https://github.com/mysql/mysql-server "$MYSQL_SRC_DIR"
    fi

    mkdir -p "${MYSQL_SRC_DIR}/build-client"
    cd "${MYSQL_SRC_DIR}/build-client"

    cmake .. \
        -DCMAKE_INSTALL_PREFIX="${MYSQL_CAPI_PREFIX}" \
        -DWITHOUT_SERVER=ON \
        -DWITH_SSL=system \
        -DWITH_TIRPC=bundled \
        -DWITH_UNIT_TESTS=OFF \
        -DENABLED_PROFILING=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=/opt/rh/gcc-toolset-13/root/usr/bin/gcc \
        -DCMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-13/root/usr/bin/g++ \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST=/tmp/mysql-boost

    # Build only the shared client library
    make -j"$(nproc)" mysqlclient libmysql

    # Install only headers and the client library — skip server tools that were not built (e.g. mysql_migrate_keyring) to avoid install errors.
    cmake --install . --component Development
    cmake --install . --component SharedLibraries

    cd /
fi

# Point cpydist at the freshly built MySQL C API
export MYSQL_CAPI="${MYSQL_CAPI_PREFIX}"
export LD_LIBRARY_PATH="${MYSQL_CAPI_PREFIX}/lib:${LD_LIBRARY_PATH}"

# cpydist's BuildExt checks for auth-plugin dir at one of:
#   $MYSQL_CAPI/lib/plugin
#   $MYSQL_CAPI/lib/mysql/plugin
#   $MYSQL_CAPI/lib64/mysql/plugin
# A client-only MySQL build has no server plugins, so none of these exist. cpydist only requires the directory to be present (it then looks for individual .so plugin files, finding none, and simply skips bundling them).
mkdir -p "${MYSQL_CAPI_PREFIX}/lib/plugin"

# Upgrade pip and install build/test tooling
pip3 install --upgrade pip setuptools wheel build
pip3 install pytest

# Return to CURRENT_DIR (set by the wrapper) before cloning so the repo
# lands at $CURRENT_DIR/mysql-connector-python — matching PACKAGE_DIR above.
cd "${CURRENT_DIR:-.}" || exit 1

# Clone the connector repository
REPO_DIR=mysql-connector-python
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR" || exit 1
else
    if ! git clone "$PACKAGE_URL" "$REPO_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
        exit 1
    fi
    cd "$REPO_DIR" || exit 1
    git checkout "$PACKAGE_VERSION" || exit 1
fi

# Move into the sub-package directory that contains pyproject.toml.
cd mysql-connector-python || exit 1

# Install with C extension.
# MYSQL_CAPI env var is read by cpydist/__init__.py (line 179) — no need to pass --with-mysql-capi flag (modern pip >= 23 rejects unknown --with-* flags).
if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Fails"
    exit 1
fi

# Run unit tests that do NOT require a live MySQL server connection.
# Excluded tests:
#   - MySQLConverter*IntegrationTests / MySQLConverterStrFallbackTests:
#     require a running mysqld (config returns None without a server).
#   - RefreshOptionTests::test_deprecated:
#     asserts against an old deprecation message string that changed in 9.7.0.
if ! python3 -m pytest tests/test_constants.py tests/test_conversion.py tests/test_errorcode.py tests/test_errors.py tests/test_locales.py tests/test_utils.py tests/test_protocol.py -k "not (MySQLConverterIntegrationTests or MySQLConverterAioIntegrationTests or MySQLConverterStrFallbackTests or test_deprecated)" -v --tb=short --disable-warnings 2>&1; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
exit 0
