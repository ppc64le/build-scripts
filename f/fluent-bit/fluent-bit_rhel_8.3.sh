# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v1.7.8
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

VERSION=363d88cf85b05515e04a2c4314fb0ab12e5ee337
FLEX_VERSION="2.6.1-9.el8"
BISON_VERSION="3.0.4-10.el8"

# Install dependencies.
yum update -y
yum install -y cmake make git gcc-c++
yum install -y http://mirror.centos.org/centos/8/AppStream/ppc64le/os/Packages/flex-${FLEX_VERSION}.ppc64le.rpm
yum install -y http://mirror.centos.org/centos/8/AppStream/ppc64le/os/Packages/bison-${BISON_VERSION}.ppc64le.rpm

# Clone source.
git clone https://github.com/fluent/fluent-bit.git
cd fluent-bit/
git checkout $VERSION

# This step assumes that you have already copied the patches directory files as a sibbling of this script.
# Added ppc64le.c file for libco(coroutine) library PPC64 little endian support.
cp ../patches/ppc64le.c lib/monkey/deps/flb_libco/ppc64le.c
cp ../patches/libco.patch .
git apply libco.patch

# No support for ppc64le in library luajit-2.1.0-1e66d0f which is already under fluent-bit/lib directory.
# Clone luajit2 in fluent-bit which supports ppc64le.
cd lib/
git clone https://github.com/openresty/luajit2.git

# This step assumes that you have already copied the patch file as a sibbling of this script
# Patch applied for PR's https://github.com/openresty/luajit2/pull/123 & https://github.com/openresty/luajit2/pull/124
cd luajit2/
cp ../../../patches/configure .
cp ../../../patches/luajit2.patch .
git apply luajit2.patch

# cmake/libraries.cmake with luajit2 lib path.
cd ../../
cp ../patches/fluent-bit-luajit2.patch .
git apply fluent-bit-luajit2.patch

# Build source
cd build/
cmake ..
make
bin/fluent-bit -i cpu -o stdout -f 1 --verbose

# Command to run Luajit in fluent-bit
# bin/fluent-bit -i dummy -F lua -p script=../scripts/test.lua -p call=cb_print -m '*' -o stdout -f 1 --verbose
