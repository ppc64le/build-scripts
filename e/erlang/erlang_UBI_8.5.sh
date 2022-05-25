#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package    : erlang
# Version    : OTP-25.0
# Source repo    : https://github.com/erlang/otp.git
# Tested on    : UBI: 8.5
# Language      : Erlang, C, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=erlang
PACKAGE_VERSION=${1:-OTP-25.0}
PACKAGE_URL=https://github.com/erlang/otp.git

yum install -y sudo
yum install -y sudo git make unzip tar gcc-c++ gcc clang ncurses ncurses-devel sed java

git clone $PACKAGE_URL
cd otp
git checkout $PACKAGE_VERSION

ERL_TOP=`pwd`

./configure

make -j $(nproc)

./otp_build setup -a

cd $ERL_TOP/lib/asn1 && make test -j $(nproc)
cd $ERL_TOP/lib/stdlib && make test ARGS="-suite ets_SUITE" -j $(nproc)
cd $ERL_TOP/erts/emulator && make test ARGS="-suite binary_SUITE -case deep_bitstr_lists" -j $(nproc)