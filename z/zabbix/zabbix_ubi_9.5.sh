#!/bin/bash -e

#
# Package       : Zabbix
# Version       : 7.4.1
# Source repo   : https://github.com/zabbix/zabbix.git
# Tested on     : RHEL 9 / UBI 9
# Language      : PHP, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution.
#


PACKAGE_NAME="zabbix"
PACKAGE_VERSION="${1:-7.4.1}"
PACKAGE_URL="https://github.com/zabbix/zabbix.git"
BUILD_DIR="/tmp/zabbix-deps"
OUTPUT_DIR="/home/tester/output"


# Update system and enable EPEL
dnf update -y --allowerasing

# Detect RHEL version and install matching EPEL release
OS_VER=$(rpm -E %{rhel} 2>/dev/null || echo "")
if [ -n "$OS_VER" ]; then
    dnf install -y --allowerasing --nobest \
        "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VER}.noarch.rpm"
else
    echo "Skipping EPEL install — not a RHEL-like system."
fi
dnf install -y --allowerasing dnf-plugins-core

# Install essential tools first
dnf install -y --allowerasing wget git cmake make gcc-c++

# Install all required dependencies
dnf install -y --allowerasing \
    autoconf automake libtool pkgconfig \
    httpd php php-mysqlnd php-xml php-gd php-bcmath php-mbstring php-ldap php-json \
    libcurl-devel libxml2-devel libevent-devel pcre-devel \
    policycoreutils procps dnf-utils libyaml-devel openssl-devel sqlite-devel \
    libssh2-devel unixODBC-devel openldap-devel libxslt-devel pcre2-devel \
    libmodbus-devel mariadb-connector-c-devel net-snmp-libs libxml2-devel

# Build and install cmocka (only if not installed)
if ! ldconfig -p | grep -q libcmocka; then
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    git clone https://git.cryptomilk.org/projects/cmocka.git
    cd cmocka
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make -j"$(nproc)"
    make install
fi


# Prepare output directory
mkdir -p "$OUTPUT_DIR"
cd /home/tester
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


# Clone Zabbix
if ! git clone "$PACKAGE_URL"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > "$OUTPUT_DIR/clone_fails"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > "$OUTPUT_DIR/version_tracker"
    exit 1
fi

cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"


# Bootstrap and configure Zabbix build
./bootstrap.sh
./configure \
    --enable-server \
    --enable-agent \
    --with-mysql \
    --enable-ipv6 \
    --with-libcurl \
    --without-libxml2 \
    --with-openssl \
    --with-ldap


# Build and install Zabbix
make -j"$(nproc)"
make install


# Run tests
echo "------------------Test the package---------------------"
if ! make tests; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > "$OUTPUT_DIR/test_fails"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > "$OUTPUT_DIR/version_tracker"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > "$OUTPUT_DIR/test_success"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > "$OUTPUT_DIR/version_tracker"
    exit 0
fi
