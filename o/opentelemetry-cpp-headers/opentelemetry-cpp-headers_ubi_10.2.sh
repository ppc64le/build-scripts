#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp-headers
# Version       : v1.27.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : UBI:10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivender Singh <shivender.singh2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=opentelemetry-cpp-headers
SOURCE_NAME=opentelemetry-cpp
PACKAGE_VERSION=${1:-v1.27.0}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-cpp
WORKING_DIR=$(pwd)

# skip_if_unavailable: ignore inherited host repos that return HTTP 403 in the container
yum install -y --setopt=skip_if_unavailable=True git gcc-c++ gcc wget make  python3 python3-pip yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

#install gtest
git clone https://github.com/google/googletest.git
cd googletest/
git checkout v1.14.0
mkdir build
cd build
cmake .. 
make &&  make install
cd "$WORKING_DIR"

git clone $PACKAGE_URL
cd $SOURCE_NAME
git checkout $PACKAGE_VERSION
SOURCE_DIR=$(pwd)

# WITH_API_ONLY: header-only API (no SDK, exporters or examples); only the API unit tests are built
mkdir build
cd build
cmake -DWITH_API_ONLY=ON -DWITH_BENCHMARK=OFF -DBUILD_TESTING=ON ..

if ! cmake --build .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Keep the ctest output so the pass/fail counts can be shown again after the wheel build
print_test_summary() {
    LOG="$WORKING_DIR/ctest.log"
    TOTAL=$(sed -n 's/.*tests failed out of \([0-9]*\).*/\1/p' "$LOG")
    FAILED=$(sed -n 's/.*, \([0-9]*\) tests failed out of.*/\1/p' "$LOG")
    echo "================ Test summary ================"
    echo "Total: ${TOTAL:-?}  Passed: $(( ${TOTAL:-0} - ${FAILED:-0} ))  Failed: ${FAILED:-?}"
    sed -n '/tests passed/,$p' "$LOG"
}

set -o pipefail
if ! ctest --verbose 2>&1 | tee "$WORKING_DIR/ctest.log"; then
    print_test_summary
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
fi

# Build wheel: install into a local prefix, then package it (setup.py is generated here)
cd "$SOURCE_DIR"
PREFIX="$SOURCE_DIR/local/opentelemetry_cpp_headers"
rm -rf "$SOURCE_DIR/local" "$SOURCE_DIR/dist"
mkdir -p "$PREFIX"
touch "$PREFIX/__init__.py"

python3 -m pip install --upgrade pip setuptools wheel build

CLEAN_VERSION="${PACKAGE_VERSION#v}"
cat > setup.py <<EOF
import os
from setuptools import setup
from setuptools.dist import Distribution

# List files only (a "**/*" glob also matches directories, which setuptools warns about)
PKG = "local/opentelemetry_cpp_headers"
FILES = [os.path.relpath(os.path.join(root, f), PKG)
         for root, _, names in os.walk(PKG) for f in names]


class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


setup(
    name="opentelemetry-cpp-headers",
    version="${CLEAN_VERSION}",
    description="OpenTelemetry C++ API headers for ppc64le",
    license="Apache-2.0",
    packages=["opentelemetry_cpp_headers"],
    package_dir={"": "local"},
    package_data={"opentelemetry_cpp_headers": FILES},
    include_package_data=False,
    distclass=BinaryDistribution,
)
EOF

if ! (cmake --install build --prefix "$PREFIX" && \
      test -f "$PREFIX/include/opentelemetry/trace/tracer.h" && \
      python3 -m build --wheel --no-isolation && \
      python3 -m zipfile -l dist/opentelemetry_cpp_headers-*.whl | grep "include/opentelemetry/trace/tracer.h" > /dev/null); then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp -f dist/opentelemetry_cpp_headers-*.whl "$WORKING_DIR/"
ls -la "$WORKING_DIR"/*.whl

print_test_summary

echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
exit 0
