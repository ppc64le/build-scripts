#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : python-oracledb
# Version       : v26.1.0
# Source repo   : https://github.com/oracle/python-oracledb.git
# Tested on     : UBI:9.6
# Language      : Python, Cython, Plsql
# Ci-Check  : True
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

PACKAGE_NAME=python-oracledb
PACKAGE_VERSION=${1:-v26.1.0}
PACKAGE_URL=https://github.com/oracle/python-oracledb.git
CURRENT_DIR=$(pwd)
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# Install dependencies
yum install -y python3.12 python3.12-devel python3.12-pip git openssl-devel \
    gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

echo " ----------------------------------- Installing Dependencies ----------------------------------- "
# pyproject.toml requires setuptools>=77.0.0 and cython~=3.3; cryptography is a
# runtime dependency, taken from the IBM wheel index to avoid a Rust build.
python3.12 -m pip install --upgrade pip "setuptools>=77.0.0" wheel build pytest "cython~=3.3"
python3.12 -m pip install --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary "cryptography>=3.2.1" "typing_extensions>=4.14.0"

# Clone the python-oracledb package (upstream tags are prefixed with 'v')
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_NAME}" ]]; then
    git clone "${PACKAGE_URL}"
fi
cd "${PACKAGE_NAME}"
git checkout "v${PACKAGE_VERSION#v}"
git submodule update --init --recursive

echo " ----------------------------------- Installing Package ----------------------------------- "
if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# The upstream test suite needs a live Oracle Database, so only verify that the
# built package imports and reports the expected version (run outside the source tree).
cd "${CURRENT_DIR}"
EXPECTED_VERSION="${PACKAGE_VERSION#v}"
if ! python3.12 -c "
import oracledb
print(oracledb.__file__)
print(oracledb.__version__)
assert oracledb.__version__ == '${EXPECTED_VERSION}', oracledb.__version__
"; then
    echo "------------------$PACKAGE_NAME::Install_success_but_test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
