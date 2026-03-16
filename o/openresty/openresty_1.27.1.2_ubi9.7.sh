#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : openresty
# Version          : v1.27.1.2
# Source repo      : https://github.com/openresty/openresty.git
# Tested on        : UBI 9.7
# Language         : C
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME="openresty"
PACKAGE_VERSION=${1:-1.27.1.2}
PACKAGE_URL="https://github.com/openresty/openresty.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} version ${PACKAGE_VERSION}"

# -------------------------------------------------------
# Install system dependencies
# -------------------------------------------------------
echo "Installing build dependencies..."
yum install -y \
        cpan \
        dos2unix \
        findutils \
        gcc-c++ \
        git \
        make \
        ncurses-devel \
        openssl-devel \
        patch \
        pcre-devel \
        perl \
        postgresql-devel \
        readline \
        sudo \
        tar \
        perl-App-cpanminus \
        perl-libwww-perl \
        unzip \
        wget \
        yum \
        zlib-devel

# ------------------------------------------------------
# Install required Perl testing modules
# ------------------------------------------------------
echo "Installing Perl test dependencies...."
PERL_MM_USE_DEFAULT=1 cpan Cwd IPC::Run3 Test::Base Test::Nginx LWP::UserAgent

# -----------------------------
# Clone and Prepare Repository
# -----------------------------
cd $SOURCE_ROOT
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}" && git checkout "v${PACKAGE_VERSION}"

wget https://openresty.org/download/openresty-${PACKAGE_VERSION}.tar.gz
tar -xvf openresty-${PACKAGE_VERSION}.tar.gz
# -------------------------------------------------------
# Download additional nginx module
# redis2-nginx-module is required but disabled by default
# -------------------------------------------------------
wget https://github.com/openresty/redis2-nginx-module/archive/refs/tags/v0.15.tar.gz
tar -xvf v0.15.tar.gz
# -------------------------------------------------------
# Clone test-nginx framework (used by OpenResty tests)
# -------------------------------------------------------
if [ ! -d "test-nginx" ]; then
    git clone https://github.com/openresty/test-nginx.git
fi


# -------------------------------------------------------
# Build and Install OpenResty
# -------------------------------------------------------
echo "Configuring OpenResty..."

cd "openresty-${PACKAGE_VERSION}"
./configure --with-debug \
        --with-pcre-jit \
        --without-http_redis2_module \
        --with-http_iconv_module \
        --with-http_postgres_module \
        --with-http_realip_module \
        --with-http_v2_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --with-http_stub_status_module \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_secure_link_module \
        --with-http_random_index_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-threads \
        --with-compat \
        --add-module=../redis2-nginx-module-0.15

echo "Building OpenResty..."
make -j"$(nproc)"
echo "Installing OpenResty..."
make install

# -------------------------------------------------------
# Configure environment
# -------------------------------------------------------
export PATH=/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:$PATH

# luarocks is used by juhu to install some lua plugins for openresty. We need to use luarocks
# as the plugin version available via openresty's own package manager (opm) are not new enough
cd /tmp/
curl -fSLO https://luarocks.org/releases/luarocks-3.12.0.tar.gz
tar xf luarocks-*.tar.gz
rm -f luarocks-*.tar.gz

cd luarocks-*
./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit
make build
make install

echo "http { server { listen 8080; } } events { use epoll; worker_connections 128; }" > /usr/local/openresty/nginx/conf/nginx.conf
ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log
ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log
chmod -R 755 /usr/local/openresty/nginx

# install JWT lib, useful for analytics. Project page: https://github.com/cdbattags/lua-resty-jwt
# TODO JKH this is currently installed by luarocks but this could change
# opm install cdbattags/lua-resty-jwt

/usr/local/openresty/luajit/bin/luarocks install --lua-dir=/usr/local/openresty/luajit --tree=/usr/local/openresty/luajit lua-resty-openssl
/usr/local/openresty/luajit/bin/luarocks install --lua-dir=/usr/local/openresty/luajit --tree=/usr/local/openresty/luajit lua-resty-jwt
/usr/local/openresty/luajit/bin/luarocks install --lua-dir=/usr/local/openresty/luajit --tree=/usr/local/openresty/luajit lua-resty-openidc
/usr/local/openresty/luajit/bin/luarocks install --lua-dir=/usr/local/openresty/luajit --tree=/usr/local/openresty/luajit lua-resty-http

# we don't need to cleanup after ourselves since we're only using this image to build
# and then only the files we want get copied over to the final image

export TEST_NGINX_BINARY=/usr/local/openresty/nginx/sbin/nginx

# -------------------------------------------------------
# Run OpenResty test suite
# -------------------------------------------------------
echo "Running OpenResty tests..."
cd "${SOURCE_ROOT}/openresty"
if prove -r -v t/; then
    echo "All tests passed successfully."
    exit 0
else
    echo "Test failures detected."
    exit 2
fi