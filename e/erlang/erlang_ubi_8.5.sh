#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package    : erlang
# Version    : OTP-25.1.2.1
# Source repo    : https://github.com/erlang/otp.git
# Tested on    : UBI: 8.5
# Language      : Erlang, C, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Mukati <Amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=erlang
PACKAGE_VERSION=${1:-OTP-25.1.2.1}
PACKAGE_URL=https://github.com/erlang/otp.git

echo "Installing required repos..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf install -qy epel-release
dnf config-manager --enable powertools

dnf install -qy git make wget sed gcc-c++ ncurses-devel java-11-openjdk-devel libxslt openssl-devel wxWidgets-devel flex-devel

git clone $PACKAGE_URL
cd otp
git checkout $PACKAGE_VERSION

export ERL_TOP=`pwd`

./configure

make -j $(nproc)

./otp_build setup -a

cd $ERL_TOP/lib/asn1 && make test -j $(nproc) 
cd $ERL_TOP/lib/stdlib && make test ARGS="-suite ets_SUITE" -j $(nproc)
cd $ERL_TOP/erts/emulator && make test ARGS="-suite binary_SUITE -case deep_bitstr_lists" -j $(nproc)



