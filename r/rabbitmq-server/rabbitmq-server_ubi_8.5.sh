#!/bin/bash  -ex
# -----------------------------------------------------------------------------
#
# Package	: rabbitmq-server 
# Version	: v3.8.9
# Source repo	: https://github.com/rabbitmq/rabbitmq-server
# Tested on	: ubi 8.5
# Language      : erlang 
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# note: 18 test cases are failing which are in parity with x86. 
# ----------------------------------------------------------------------------

PACKAGE_NAME="rabbitmq-server"
PACKAGE_VERSION=${1:-"v3.8.9"}
PACKAGE_URL="https://github.com/rabbitmq/rabbitmq-server"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "installing dependencies from system repo..."
yum install -y git glibc-locale-source make libxslt-devel ncurses-devel gcc-c++ openssl-devel wget perl-devel automake python3-devel bash-completion nc unzip shadow-utils wget which tar gzip bash ca-certificates rsync xz zlib m4 hostname glibc-langpack-en findutils java-1.8.0-openjdk-headless unixODBC-devel diffutils >/dev/null

#building and installing erlang
git clone -q https://github.com/erlang/otp
cd otp || exit
git checkout OTP-23.3.4.11
localedef -c -f UTF-8 -i en_US en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ERL_TOP=$PWD
export PATH=$PATH:$ERL_TOP/bin
https://github.com/rabbitmq/rabbitmq-server/commit/d94b4208a5b61ef658d901ad4de76337b67d6e0b
export ERL_LIBS=''
expo rt MAKEFLAGS=-j4
find "$PWD" -name "config.guess" -exec sh -c 'cp /usr/share/automake*/config.guess $1' _ {} \;
./scripts/build-otp
#./otp_build tests && echo "sucessfully tests passed otp"
#./scripts/run-smoke-tests && echo "sucessfully smoke passed"
make install
unset MAKEFLAGS

git clone -q https://github.com/elixir-lang/elixir "$HOME_DIR"/elixir
cd "$HOME_DIR"/elixir || exit
git checkout v1.9
make compile
dialyzer -pa lib/elixir/ebin --build_plt --output_plt elixir.plt --apps lib/elixir/ebin/elixir.beam lib/elixir/ebin/Elixir.Kernel.beam
make install

echo "cloning..."
if ! git clone -q $PACKAGE_URL "$HOME_DIR"/$PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1
update-alternatives --set python /usr/bin/python3
pip3 install simplejson

if ! make; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! make tests; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
