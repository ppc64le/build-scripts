#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 12.3.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:9.6
# Language      : Python, C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryder Salinas <rbsalinas@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_IMPORT=PIL
PACKAGE_DIR=Pillow
PACKAGE_VERSION="${1:-12.3.0}"
PACKAGE_VERSION="${PACKAGE_VERSION#v}"
PACKAGE_URL="https://github.com/python-pillow/Pillow/"
SOURCE_ROOT="$(pwd)"

export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"

# Install core and Pillow dependencies
dnf install -y python3.12 python3.12-pip python3.12-devel git gcc-toolset-15 \
    zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel wget freetype-devel

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"

# Install build tools
python3.12 -m pip install --upgrade pip setuptools wheel build pytest \
    --only-binary=numpy numpy \
    --extra-index-url "${INDEX_URL_DEVPY}"

# Clone and build
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
git submodule update --init

python3.12 -m build --wheel --outdir "${SOURCE_ROOT}"

WHEEL=$(find "${SOURCE_ROOT}" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

if ! python3.12 -m pip install "$WHEEL"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Import and version test
echo "Import and Version Test"
python3.12 -c "
import ${PACKAGE_IMPORT}
from importlib.metadata import version
print('Import successful:', ${PACKAGE_IMPORT}.__file__)
print('Version:', version('${PACKAGE_NAME}'))
print('Import and version: OK')
"

# Run tests
if ! pytest -k "not test_segfault"; then
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