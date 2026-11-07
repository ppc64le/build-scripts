#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : psycopg2
# Version       : 2.9.13
# Source repo   : https://github.com/psycopg/psycopg2
# Tested on     : UBI:9.6
# Language      : Python, C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=psycopg2
PACKAGE_VERSION=${1:-2.9.13}
PACKAGE_URL=https://github.com/psycopg/psycopg2
CURRENT_DIR=$(pwd)

# Install required system packages (libpq headers and pg_config come from libpq-devel)
yum install -y git python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc make libpq-devel openssl-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

# pyproject.toml requires setuptools>=70.1 (setup.py uses the distutils shim from setuptools)
python3.12 -m pip install --upgrade pip "setuptools>=70.1" wheel pytest

# Clone the package repository (tags: 2.9.6 and later use dots, older ones use underscores, e.g. 2_9_5)
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_NAME}" ]]; then
    git clone "${PACKAGE_URL}" "${PACKAGE_NAME}"
fi
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Build and install from source
if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# The upstream test suite needs a running PostgreSQL server, so only verify that the
# compiled extension loads and reports the expected version (run outside the source tree).
cd "${CURRENT_DIR}"
if ! python3.12 -c "
import psycopg2
from psycopg2 import extensions, _psycopg
print(psycopg2.__file__)
print(psycopg2.__version__)
print('libpq', extensions.libpq_version())
assert psycopg2.__version__.split()[0] == '${PACKAGE_VERSION}', psycopg2.__version__
"; then
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
