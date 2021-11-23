# ----------------------------------------------------------------------------
#
# Package               : jq
# Version               : 1.6
# Source repo           : https://github.com/stedolan/jq.git
# Tested on             : RHEL 8.4
# Script License        : Apache License Version 2.0
# Maintainer            : Kandarpa Malipeddi <kandarpa.malipeddi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

VERSION=${1:-jq-1.6}

echo ###############################
echo      Buillding $VERSION
echo ###############################

yum install -y autoconf automake make git gcc-c++ perl cmake  diffutils libtool

# This will install valgrind under /usr/local/bin
# Valgrind is required to validate jq by running memory tests.

cd
git clone git://sourceware.org/git/valgrind.git
cd valgrind/
git checout VALGRIND_3_18_1
./autogen.sh
./configure
make -j
make install


cd
git clone https://github.com/stedolan/jq.git
cd jq
git checkout $VERSION
git submodule update --init
autoreconf -fi
./configure --with-oniguruma=builtin
make -j
make check -j
make install

jq --version
