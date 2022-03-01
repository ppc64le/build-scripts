#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : openresty
# Version       : 1.19.9.1
# Source repo   :  https://openresty.org/download/openresty
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaibhav Bhadade <vaibhav.bhadade@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
set -x
ARCH=$(uname -m)


# common deps
yum install -y unzip make gcc-c++ tar findutils sudo wget yum ncurses-devel patch perl curl tar cpan postgresql-devel pcre-devel openssl-devel dos2unix libpq 

PACKAGE_NAME="openresty"
PACKAGE_VERSION="1.19.9.1"
ROLLBACK_VERSION="1.17.8.2"
SOURCE_ROOT="$(pwd)"
PATCH_URL="https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/OpenResty/1.19.3.2/patch"

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
PATCH_FILE=$SCRIPT_DIR/LuaJIT_2_1.patch

ls $PATCH_FILE
cd $SOURCE_ROOT
wget https://openresty.org/download/openresty-${PACKAGE_VERSION}.tar.gz
tar -xvf openresty-${PACKAGE_VERSION}.tar.gz
#Download previous version to rollback selected modules due to a lua core issue.
#issue for reference https://github.com/kubernetes/ingress-nginx/issues/6504 - is fixed in openrestry 1.17.8.2 hence it is marked as close
#however any newer version of openresty we need this workaround to avoid lua core issue
printf -- "Start rollback modules... \n"
cd $SOURCE_ROOT
wget https://openresty.org/download/openresty-${ROLLBACK_VERSION}.tar.gz
tar -xvf openresty-${ROLLBACK_VERSION}.tar.gz
rm -rf openresty-${PACKAGE_VERSION}/bundle/lua-resty-core-*
rm -rf openresty-${PACKAGE_VERSION}/bundle/ngx_lua-*
rm -rf openresty-${PACKAGE_VERSION}/bundle/ngx_stream_lua-*
cp -r openresty-${ROLLBACK_VERSION}/bundle/lua-resty-core-* openresty-${PACKAGE_VERSION}/bundle/
cp -r openresty-${ROLLBACK_VERSION}/bundle/ngx_lua-* openresty-${PACKAGE_VERSION}/bundle/
cp -r openresty-${ROLLBACK_VERSION}/bundle/ngx_stream_lua-* openresty-${PACKAGE_VERSION}/bundle/
rm -rf "$SOURCE_ROOT/openresty-${ROLLBACK_VERSION}"
printf -- "Rollback modules success \n"

# Apply configure file patch for older GCC
cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
curl -o "configure.diff" $PATCH_URL/configure.diff
patch -l $SOURCE_ROOT/openresty-${PACKAGE_VERSION}/configure configure.diff

# Apply lj_ccallback.c file patch 
cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
patch -l  $SOURCE_ROOT/openresty-${PACKAGE_VERSION}/bundle/LuaJIT-2.1-20210510/src/lj_ccallback.c  $PATCH_FILE

# add redis2-nginx-module-0.15 module
cd $SOURCE_ROOT
wget https://github.com/openresty/redis2-nginx-module/archive/refs/tags/v0.15.tar.gz
tar -xvf v0.15.tar.gz

#Build and install OpenResty
cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
./configure --with-pcre-jit \
        --with-ipv6 \
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
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-threads \
        --with-compat \
        --add-module=../redis2-nginx-module-0.15
make -j2
sudo make install
#Set Environment Variable
export PATH=/usr/local/openresty/bin:$PATH
sudo cp -r /usr/local/openresty/ /usr/local/bin

cd /tmp/
curl -fSLO https://luarocks.org/releases/luarocks-3.0.4.tar.gz
tar xf luarocks-3.0.4.tar.gz
cd luarocks-3.0.4
./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit
make build
make install
echo "http { server { listen 8080; } } events { use epoll; worker_connections 128; }" > /usr/local/openresty/nginx/conf/nginx.conf
ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log
ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log
chmod -R a+w /usr/local/openresty/nginx

export PATH=/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:$PATH
export PATH=$PATH:/sbin

#Install cpan modules
PERL_MM_USE_DEFAULT=1 cpan Cwd IPC::Run3 Test::Base Test::Nginx
cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
#Download files and modify to run sanity tests
mkdir t && cd t
wget https://raw.githubusercontent.com/openresty/openresty/v${PACKAGE_VERSION}/t/Config.pm
wget https://raw.githubusercontent.com/openresty/openresty/v${PACKAGE_VERSION}/t/000-sanity.t

curl -o "Config.pm.diff"  $PATCH_URL/Config.pm.diff
patch -l $SOURCE_ROOT/openresty-1.19.9.1/t/Config.pm Config.pm.diff
patch -l $SOURCE_ROOT/openresty-1.19.9.1/t/000-sanity.t  $SOURCE_ROOT/000-sanity.t.diff
printf -- "Updated openresty-${PACKAGE_VERSION}/t/Config.pm \n"


#revert patch 
cd $SOURCE_ROOT/openresty-1.19.9.1
curl -o "configure.diff" $PATCH_URL/configure.diff
patch -l -R $SOURCE_ROOT/openresty-1.19.9.1/configure configure.diff

cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
prove -r -v t/
