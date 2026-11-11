#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp
# Version       : v1.27.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : UBI:10.2
# Language      : C++
# Ci-Check  : True
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
PACKAGE_NAME=opentelemetry-cpp
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
cd ../..

#install benchmark 
git clone https://github.com/google/benchmark.git
cd benchmark
cmake -E make_directory "build"
cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../
cmake --build "build" --config Release
cmake -E chdir "build" ctest --build-config Release
cmake --build "build" --config Release --target install
cd "$WORKING_DIR"

git clone --recursive $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
SOURCE_DIR=$(pwd)

mkdir build
cd build
cmake ..

if ! cmake --build .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ctest --verbose; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
fi

# Build wheel: install into a local prefix, then package it (setup.py is generated here)
cd "$SOURCE_DIR"
PREFIX="$SOURCE_DIR/local/opentelemetry_cpp"
rm -rf "$SOURCE_DIR/local" "$SOURCE_DIR/dist"
mkdir -p "$PREFIX"
touch "$PREFIX/__init__.py"

python3 -m pip install --upgrade pip setuptools wheel build

CLEAN_VERSION="${PACKAGE_VERSION#v}"
cat > setup.py <<EOF
from setuptools import setup
from setuptools.dist import Distribution


class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


setup(
    name="opentelemetry-cpp",
    version="${CLEAN_VERSION}",
    description="OpenTelemetry C++ headers and libraries for ppc64le",
    license="Apache-2.0",
    packages=["opentelemetry_cpp"],
    package_dir={"": "local"},
    package_data={"opentelemetry_cpp": ["**/*"]},
    include_package_data=True,
    distclass=BinaryDistribution,
)
EOF

if ! (cmake --install build --prefix "$PREFIX" && \
      test -f "$PREFIX/include/opentelemetry/trace/tracer.h" && \
      python3 -m build --wheel --no-isolation); then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp -f dist/opentelemetry_cpp-*.whl "$WORKING_DIR/"
ls -la "$WORKING_DIR"/*.whl

echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
exit 0
