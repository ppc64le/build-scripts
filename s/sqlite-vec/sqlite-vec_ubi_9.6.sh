#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sqlite-vec
# Version          : v0.1.9
# Source repo      : https://github.com/asg017/sqlite-vec.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=sqlite-vec
PACKAGE_VERSION=${1:-v0.1.9}
PACKAGE_URL=https://github.com/asg017/sqlite-vec.git
CURRENT_DIR="${PWD}"

echo "Installing system dependencies..."

dnf install -y git make gcc gcc-c++ unzip gettext sqlite sqlite-libs sqlite-devel python3.12 python3.12-pip python3.12-devel

echo "Enable newer GCC if available..."
if [ -f /opt/rh/gcc-toolset-14/enable ]; then
    source /opt/rh/gcc-toolset-14/enable
fi

echo "Upgrading Python build tools..."
python3.12 -m pip install --upgrade pip setuptools wheel build

echo "Cloning repository..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Building sqlite-vec core..."

./scripts/vendor.sh
make sqlite-vec.h
make all

echo "Checking build output..."
ls -l dist/

echo "Creating Python package structure..."

mkdir -p python/sqlite_vec
cp dist/vec0.so python/sqlite_vec/

# Create __init__.py
cat <<EOF > python/sqlite_vec/__init__.py
import sqlite3
import os

def load(conn):
    path = os.path.join(os.path.dirname(__file__), "vec0.so")
    conn.enable_load_extension(True)
    conn.load_extension(path)
EOF

PKG_VER_CLEAN=${PACKAGE_VERSION#v}

# Create setup.py
cat <<EOF > python/setup.py
from setuptools import setup, find_packages

setup(
    name="sqlite-vec",
    version="${PKG_VER_CLEAN}",
    packages=find_packages(),
    package_data={"sqlite_vec": ["vec0.so"]},
    include_package_data=True,
)
EOF

cd python

echo "Building wheel..."

if ! python3.12 -m build --wheel ; then
    echo "------------------$PACKAGE_NAME:Wheel_Build_Fails---------------------"
    exit 1
fi

echo "Installing built wheel..."

python3.12 -m pip install dist/*.whl

echo "Running validation test..."

python3.12 - <<EOF
import sqlite3
import sqlite_vec

conn = sqlite3.connect(":memory:")

try:
    sqlite_vec.load(conn)
    print("sqlite-vec loaded successfully via Python package")
except Exception as e:
    print("Error:", e)
    exit(1)
EOF

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:Test_Fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_Test_Success---------------------"
    exit 0
fi
