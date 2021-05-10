# ----------------------------------------------------------------------------
# Package       : openresty
# Version       : v1.19.3.1
# Source repo   : https://github.com/openresty/openresty
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna Harsha Voora
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#!/bin/bash
# clone branch/release passed as argument, if none, use last release: v1.19.3.1

if [ -z $1 ] || [ "$1" == "lasttestedrelease" ]
then
       # As on Nov-2020, release v1.19.3.1 is the unverified tag/release
       # And does not work on v1.15.8.3 release

       BRANCH="--branch v1.19.3.1"
else
       BRANCH="--branch $1"
fi

echo "BRANCH = $BRANCH"

#########################
# Export Variables
#########################

export JOBS=3
export PCRE_VER=8.44
export PCRE_PREFIX=/opt/pcre
export PCRE_LIB=$PCRE_PREFIX/lib
export PCRE_INC=$PCRE_PREFIX/include
export OPENSSL_PREFIX=/opt/ssl
export OPENSSL_LIB=$OPENSSL_PREFIX/lib
export OPENSSL_INC=$OPENSSL_PREFIX/include
export OPENRESTY_PREFIX=/opt/openrest
export OPENSSL_VER=1.1.1f
export OPENSSL_PATCH_VER=1.1.1f

#########################
# Clone Repository
#########################

(git clone  $BRANCH https://github.com/openresty/openresty/) || (echo "git clone failed"; exit $?)
cd openresty


#########################
# Unpack / Build / Install from Comprehensiv Perl Archive Network CPAN
#########################

cpanm --notest Test::Nginx IPC::Run3 > build.log 2>&1 || (cat build.log && exit 1)


#########################
# Unpack / Build / Install PCRE Libraries
# This did not work with upstream's pcre library
#########################

wget -P download-cache https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VER.tar.gz
tar zxf download-cache/pcre-$PCRE_VER.tar.gz
cd pcre-$PCRE_VER/
./configure --prefix=$PCRE_PREFIX --enable-jit --enable-utf --enable-unicode-properties > build.log 2>&1 || (cat build.log && exit 1)
make -j$JOBS > build.log 2>&1 || (cat build.log && exit 1)
PATH=$PATH make install > build.log 2>&1 || (cat build.log && exit 1)
cd ../


#########################
# Unpack / Build / Install openssl
#########################

wget -P download-cache https://www.openssl.org/source/old/${OPENSSL_VER//[a-z]/}/openssl-$OPENSSL_VER.tar.gz
tar zxf download-cache/openssl-1.1.1f.tar.gz
cd openssl-$OPENSSL_VER/
patch -p1 < ../patches/openssl-$OPENSSL_PATCH_VER-sess_set_get_cb_yield.patch
./config no-threads shared enable-ssl3 enable-ssl3-method -g --prefix=$OPENSSL_PREFIX -DPURIFY > build.log 2>&1 || (cat build.log && exit 1)
make -j$JOBS > build.log 2>&1 || (cat build.log && exit 1)
make PATH=$PATH install_sw > build.log 2>&1 || (cat build.log && exit 1)
cd ../

# Soft Link gmake / make
# ln -s /usr/bin/make /usr/bin/gmake ----> Not Needed in RHEL



#########################
# Pull lua/ nginx libraries
#########################

util/mirror-tarballs > build.log 2>&1 || (cat build.log && exit 1)
cd openresty-`util/ver`


#########################
# Build / Install LuaJIT2/NGINX
#########################

./configure --prefix=$OPENRESTY_PREFIX --with-cc-opt="-I$PCRE_INC -I$OPENSSL_INC" --with-ld-opt="-L$PCRE_LIB -L$OPENSSL_LIB -Wl,-rpath,$PCRE_LIB:$OPENSSL_LIB" --with-pcre-jit --with-http_ssl_module --with-debug -j$JOBS > build.log 2>&1 || (cat build.log && exit 1)
make -j$JOBS > build.log 2>&1 || (cat build.log && exit 1)
make install > build.log 2>&1 || (cat build.log && exit 1)
cd ..
export PATH=$OPENRESTY_PREFIX/bin:$OPENRESTY_PREFIX/nginx/sbin:$PATH
echo "########### Nginx Version"
nginx -V
ldd `which nginx`|grep -E 'luajit|ssl|pcre'

#########################
# Run default tests
#########################

if [ "$2" == "runtest" ]
then
        # Run TAP based tests
        prove -r t/
fi


#########################
# Copy Binaries/ libraries
#########################

cd /opt/openrest/
tar cf $HOME/openrest.tar /opt/openrest/
cp $HOME/openrest.tar  /ws/

#########################
# Clean-Up
#########################
rm -rf /ws//openresty/
