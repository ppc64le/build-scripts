#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyproj
# Version       : 3.8.0
# Source repo   : https://github.com/pyproj4/pyproj
# Tested on     : UBI:9.6
# Language      : Python, Cython
# Ci-Check      : True
# Script License: Apache License 2.0
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

PACKAGE_NAME=pyproj
PACKAGE_VERSION=${1:-3.8.0}
PACKAGE_URL=https://github.com/pyproj4/pyproj.git
PACKAGE_DIR=pyproj
HOME_DIR=${PWD}

# pyproj 3.8.0 needs PROJ >= 9.4.0 (PROJ_MIN_VERSION in setup.py)
PROJ_VERSION=9.8.0
PROJ_PREFIX=${HOME_DIR}/proj-install

# Upstream tags have no 'v' prefix (accept both forms)
VERSION_NUM="${PACKAGE_VERSION#v}"

# pyproj 3.8.0 declares requires-python >= 3.12, so it cannot be built on older interpreters.
# The wheel wrapper passes the Python version as $2 (e.g. 3.11); direct runs default to 3.12.
PY_VER=${2:-3.12}
if [[ "$(printf '%s\n' "3.12" "${PY_VER}" | sort -V | head -n1)" != "3.12" ]]; then
    echo "Skipping: ${PACKAGE_NAME} ${PACKAGE_VERSION} requires Python >= 3.12 (got ${PY_VER})"
    exit 0  # early exit; the trailing comment keeps the wheel wrapper from stripping this line
fi

# Install dependencies and tools.
# PROJ needs the sqlite3 binary (to build proj.db), libsqlite3, libtiff and libcurl.
yum install -y git make cmake python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    sqlite sqlite-devel libtiff-devel libcurl-devel openssl-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

# Build and install PROJ (required to build pyproj from source)
cd "${HOME_DIR}"
rm -rf PROJ
git clone --depth 1 --branch "${PROJ_VERSION}" https://github.com/OSGeo/PROJ.git
cd PROJ
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX="${PROJ_PREFIX}"
make -j"$(nproc)"
make install

# Python build requirements (pyproject.toml: setuptools>=77.0.1, cython>=3.1)
python3.12 -m pip install --upgrade pip wheel "setuptools>=77.0.1" "cython>=3.1" certifi

# Clone pyproj
cd "${HOME_DIR}"
rm -rf "${PACKAGE_DIR}"
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"
git checkout "${VERSION_NUM}"

export PROJ_DIR=${PROJ_PREFIX}
export PROJ_VERSION
export LD_LIBRARY_PATH=${PROJ_PREFIX}/lib64:${PROJ_PREFIX}/lib:${LD_LIBRARY_PATH}
export PROJ_DATA=${PROJ_PREFIX}/share/proj

# Build and install
if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Smoke test (run outside the source tree so the installed build is used):
# import, version check and a real coordinate transformation using proj.db.
cd "${HOME_DIR}"
if ! python3.12 -c "
import pyproj
from pyproj import Transformer
print('pyproj version:', pyproj.__version__)
print('PROJ version  :', pyproj.proj_version_str)
assert pyproj.__version__ == '${VERSION_NUM}', pyproj.__version__
t = Transformer.from_crs('EPSG:4326', 'EPSG:32633', always_xy=True)
x, y = t.transform(15.0, 0.0)
assert abs(x - 500000.0) < 1e-3 and abs(y) < 1e-3, (x, y)
print('transform OK:', x, y)
"; then
    echo "------------------$PACKAGE_NAME::Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
