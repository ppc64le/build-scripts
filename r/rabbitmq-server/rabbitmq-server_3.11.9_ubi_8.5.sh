#!/bin/bash  -ex
# -----------------------------------------------------------------------------
#
# Package	: rabbitmq-server 
# Version	: v3.11.9
# Source repo	: https://github.com/rabbitmq/rabbitmq-server
# Tested on	: ubi 8.5
# Language      : erlang 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="rabbitmq-server"
PACKAGE_VERSION=${1:-"v3.11.9"}
PACKAGE_URL="https://github.com/rabbitmq/rabbitmq-server"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "Installing required repos..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf install -qy epel-release
dnf config-manager --enable powertools

dnf install -qy wxWidgets-devel flex-devel libxslt sed java-11-openjdk-devel

echo "installing dependencies from system repo..."
yum install -y git glibc-locale-source make libxslt-devel ncurses-devel openssl-devel gcc-c++ wget perl-devel automake python3-devel bash-completion nc unzip shadow-utils wget which tar gzip bash ca-certificates rsync xz zlib m4 hostname glibc-langpack-en findutils  unixODBC-devel diffutils >/dev/null


#building and installing erlang
git clone -q https://github.com/erlang/otp
cd otp || exit
git checkout OTP-25.1.2.1
export ERL_TOP=$PWD
./configure
make
make install


# building and installing elixir
git clone -q https://github.com/elixir-lang/elixir "$HOME_DIR"/elixir
cd "$HOME_DIR"/elixir || exit
git checkout v1.14.3
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