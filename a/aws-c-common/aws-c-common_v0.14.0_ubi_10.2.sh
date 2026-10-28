#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aws-c-common
# Version       : v0.14.0
# Source repo   : https://github.com/awslabs/aws-c-common.git
# Tested on     : UBI:10.2
# Language      : C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=aws-c-common
SCRIPT_PACKAGE_VERSION=v0.14.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/awslabs/aws-c-common
PACKAGE_DIR=aws-c-common

BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install build dependencies
yum install -y --disablerepo='rhel-*' gcc gcc-c++ cmake make git wget \
    openssl-devel zlib-devel

# Add CentOS Stream 10 repos for additional packages if needed
yum install -y --disablerepo='rhel-*' yum-utils

yum config-manager --add-repo https://mirror.stream.centos.org/10-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/10-stream/BaseOS/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/10-stream/CRB/ppc64le/os/
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256

# Clone repository
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"

# Detect Power10 and set optimised flags; generic fallback otherwise
if grep -iq "POWER10" /proc/cpuinfo 2>/dev/null || lscpu 2>/dev/null | grep -iq "POWER10"; then
    echo "Power10 CPU detected — enabling -mcpu=power10 -mtune=power10"
    export CFLAGS="-mcpu=power10 -mtune=power10"
    export CXXFLAGS="$CFLAGS"
fi

# Build
mkdir -p build
cd build

# aws-c-common is a pure C library; USE_CPU_EXTENSIONS only handles Intel/ARM
# so it is left at its default (OFF on ppc64le the generic arch path is used).
if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=ON; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! make -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run the full upstream test suite
if ! ctest --output-on-failure; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
