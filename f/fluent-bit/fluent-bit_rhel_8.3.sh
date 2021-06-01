# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v1.7.5
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Maniraj Deivendran <maniraj.deivendran@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

VERSION="master"
FLEX_VERSION="2.6.1-9.el8"
BISON_VERSION="3.0.4-10.el8"

# Install dependencies.
yum update -y
yum install -y cmake make git gcc-c++
yum install -y http://mirror.centos.org/centos/8/AppStream/ppc64le/os/Packages/flex-${FLEX_VERSION}.ppc64le.rpm
yum install -y http://mirror.centos.org/centos/8/AppStream/ppc64le/os/Packages/bison-${BISON_VERSION}.ppc64le.rpm

# Clone source.
git clone https://github.com/fluent/fluent-bit
cd fluent-bit/
git checkout $VERSION

# This step assumes that you have already copied the patches directory files as a sibbling of this script.
# Added ppc64le.c file for libco(coroutine) library PPC64 little endian support.
cp ../patches/ppc64le.c lib/monkey/deps/flb_libco/ppc64le.c
cp ../patches/libco.patch .
git apply libco.patch

# Build source
cd build/
cmake -DFLB_LUAJIT=Off -DFLB_FILTER_LUA=Off ..
make
bin/fluent-bit -i cpu -o stdout -f 1
