!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : musl
# Version          : 1.2.3
# Source repo      : https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.3.tar.gz
# Tested on        : UBI 8.5
# Language         : C++
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

# Variables

PACKAGE_NAME=musl
PACKAGE_URL=https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.3.tar.gz
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=1.2.3


yum install -y git autoconf automake libtool make unzip gcc-c++ wget

wget $PACKAGE_URL

cd $PACKAGE_NAME


# configure will fail due to musl does not support ppc64 little endian


./configure


# make will fail due changes needed in code/tool chain build suggested by musl ommunity
make

make install

