#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : searxng
# Version       : 8e824017dc88cebe5a42ee6ca04315ca9545f717
# Source repo   : https://github.com/searxng/searxng.git
# Tested on     : UBI 9.7
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=searxng
PACKAGE_VERSION=${1:-8e824017dc88cebe5a42ee6ca04315ca9545f717}
PACKAGE_URL=https://github.com/searxng/searxng.git
cwd=$(pwd)

# Set environment variables
export SEARXNG_PORT=8888
export SEARXNG_BIND_ADDRESS=0.0.0.0
export SEARXNG_SECRET="$(python3 - <<'EOF'
import secrets
print(secrets.token_hex(32))
EOF
)"

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf -y update && \
dnf -y install git \
        python3.12 python3.12-pip python3.12-devel \
        gcc nginx openssl hostname \
        shadow-utils sudo gcc-c++ \
        make wget \
        libxml2 libxml2-devel libxslt libxslt-devel

# Set python3 to point to python3.12
alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 10 && alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20 && alternatives --set python3 /usr/bin/python3.12

# --- Upgrade SQLite to >=3.35 (required by SearXNG) ---
cd /tmp && \
    wget https://www.sqlite.org/2025/sqlite-autoconf-3510000.tar.gz && \
    tar xzf sqlite-autoconf-3510000.tar.gz && \
    cd sqlite-autoconf-3510000 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && make install && \
    ln -sf /usr/local/bin/sqlite3 /usr/bin/sqlite3 && \
    ldconfig && \
    sqlite3 --version && cd .. && \
    rm -rf /tmp/sqlite-autoconf-3510000 && \
    rm -f /tmp/sqlite-autoconf-3510000.tar.gz

# Return to original directory
cd $cwd
# Clone SearXNG repository and checkout sha256
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# fix for dubious ownership issue for git
git config --global --add safe.directory /home/tester

git clone $PACKAGE_URL  && cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# ============================================================================
# REMOVE ODbL-LICENSED FILES FOR LICENSE COMPLIANCE
# ============================================================================
echo "=========================================="
echo "Removing ODbL-licensed files for compliance..."
echo "=========================================="

# Remove OpenLayers library (flagged by license scanner as ODbL-1.0)
if [ -f "searx/static/themes/simple/js/ol.min.js" ]; then
    rm -f searx/static/themes/simple/js/ol.min.js
    rm -f searx/static/themes/simple/js/ol.min.js.map
    echo "✓ Removed: searx/static/themes/simple/js/ol.min.js"
    echo "✓ Removed: searx/static/themes/simple/js/ol.min.js.map"
    echo "  Impact: Map view feature will be disabled"
else
    echo "⚠ File not found: searx/static/themes/simple/js/ol.min.js"
fi

echo "=========================================="
echo "ODbL-licensed files removal complete."
echo "=========================================="
# ============================================================================

if ! (python3 -m pip install --upgrade pip setuptools wheel && python3 -m pip install msgspec uvloop orjson pyyaml requests uwsgi pybind11 httpx && python3 -m pip install -e . --use-pep517 --no-build-isolation) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# install test dependencies
pip install pytest aiounittest mock parameterized sniffio

# Run tests
if ! pytest -k "not robot" ; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
