#--------------------------------------------------------------
# Package		: Kong
# Version		: 2.1.4(latest)
# Source repo		: https://github.com/Kong/kong
# Tested on		: UBI7
# Script License	: 
# Maintainer		: Nishikant Thorat()
#
# Disclaimer            : This script has been tested in root mode 
#			  on UBI 7 image.
#--------------------------------------------------------------
#
# Build script for Kong
#
#!/bin/bash -x
set -xv
export PATH=$HOME/openresty-build-tools/build/openresty/bin:$HOME/openresty-build-tools/build/openresty/nginx/sbin:$HOME/openresty-build-tools/build/luarocks/bin:$PATH
export OPENSSL_DIR=$HOME/openresty-build-tools/build/openssl
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export VERSION=2.1.4
#
# Basic package installation
#
yum -y  install libtool zlib zlib-devel unzip zip make lua-devel wget git patch  make gcc-c++ ncurses-devel
wget https://www.rpmfind.net/linux/epel/7/ppc64le/Packages/l/luarocks-2.3.0-1.el7.ppc64le.rpm
rpm -i luarocks-2.3.0-1.el7.ppc64le.rpm
# Valgrind needed only for debug build(optional)
wget https://www.rpmfind.net/linux/fedora-secondary/releases/30/Everything/ppc64le/os/Packages/v/valgrind-3.14.0-15.fc30.ppc64le.rpm
rpm -i valgrind-3.14.0-15.fc30.ppc64le.rpm
wget https://rpmfind.net/linux/fedora-secondary/releases/30/Everything/ppc64le/os/Packages/v/valgrind-devel-3.14.0-15.fc30.ppc64le.rpm
rpm -i valgrind-devel-3.14.0-15.fc30.ppc64le.rpm
# Lua5.1.5
wget ftp://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz && tar -xzf readline-7.0.tar.gz && cd readline-7.0 && ./configure && make && make install && cd ..
wget https://www.lua.org/ftp/lua-5.1.5.tar.gz && tar -xzvf lua-5.1.5.tar.gz &&  cd  lua-5.1.5 && make linux && cd ..
# libyaml
git clone https://github.com/yaml/libyaml.git && cd libyaml && git checkout tags/0.1.4 && ./bootstrap && ./configure && make && make install && cd ..
#
# Install kong
#
git clone https://github.com/kong/openresty-build-tools &&
cd openresty-build-tools &&
#
# Changes for picking correct luaJIT 
#
lineNum=$(grep -n "tar -xzvf openresty-\$OPENRESTY_VER.tar.gz" kong-ngx-build | tr -s " " " " |cut -d: -f 1) &&
lineNum=`expr $lineNum + 1` &&
sed -i  -e ''$lineNum'icd -' kong-ngx-build &&
# Adding flags for GC64, to avoid issues due to insufficent memory. 
sed -i 's/OPENRESTY_OPTS+=('"'"'--with-pcre=$PCRE_DOWNLOAD'"'"')/OPENRESTY_OPTS+=('"'"'--with-pcre=$PCRE_DOWNLOAD --with-luajit-xcflags="-DLUAJIT_ENABLE_GC64" '"'"')/' kong-ngx-build &&
sed -i  -e ''$lineNum'igit checkout 2763a421d6219c8cb2bbd39246de619dc796bab6 ' kong-ngx-build &&
sed -i  -e ''$lineNum'icd openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build &&
sed -i  -e ''$lineNum'igit clone https://github.com/openresty/luajit2.git openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build &&
sed -i  -e ''$lineNum'imkdir openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build &&
sed -i  -e ''$lineNum'irm -rf openresty-${OPENRESTY_VER}/bundle/LuaJIT-*/' kong-ngx-build && 
# End
./kong-ngx-build  -p build --no-openresty-patches --openresty 1.15.8.2 --openssl 1.1.1d --pcre 8.43 --luarocks 3.2.1

git clone https://github.com/Kong/kong && cd kong && git checkout $VERSION && ulimit -n 65536 && luarocks make  OPENSSL_DIR=$HOME/openresty-build-tools/build/openssl/ 
#
# Deleting grpcurl from Makefile
#
lineNum=$(grep -n grpcurl: Makefile | cut -d: -f 1) &&
begin=`expr $lineNum + 1` && end=`expr $lineNum + 3` &&
sed -i -e ''$begin,$end'd' Makefile
# End
make dev && ulimit -n 65536 && eval $(luarocks path --bin) && make test
