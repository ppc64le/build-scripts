# ----------------------------------------------------------------------------
#
# Package       : KongAPI
# Version       : 0.12.3-0 
# Source repo   : https://github.com/Kong/kong.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install -y make gcc g++ bzip2 git curl wget vim zlib1g-dev \
    luarocks net-tools libpcre3-dev build-essential libcrypto++-dev libssl-dev

#Building luajit needed for openresty
mkdir /tmp/luajit
cd /tmp/luajit
curl -k -L https://api.github.com/repos/PPC64/LuaJIT/tarball > luajit.tar.gz
tar -zxf luajit.tar.gz
cd PPC64-LuaJIT-*
make && sudo make install
rm -rf /tmp/luajit
luajitdir="=/usr/local"

#Building openresty(Needed for Kong testing) from source
cd $HOME
wget https://openresty.org/download/openresty-1.13.6.1.tar.gz
tar -xzvf openresty-1.13.6.1.tar.gz
cd openresty-1.13.6.1
./configure --with-luajit${luajitdir} --with-ipv6 --with-http_realip_module \
  --with-http_ssl_module --with-http_stub_status_module \
  --with-http_v2_module -j2
make && sudo make install
export PATH=$PATH:/usr/local/openresty/bin
rm -rf openresty-1.13.6.1.tar.gz

#Build the KongAPI
cd $HOME
git clone https://github.com/Kong/kong
cd kong
git checkout next

sudo luarocks make CRYPTO_LIBDIR=/usr/lib/powerpc64le-linux-gnu OPENSSL_LIBDIR=/usr/lib/powerpc64le-linux-gnu

sudo make dev
#Reinstalling luarocks
sudo luarocks install luarocks
make test

# NOTE: If `make test` fails with "module 'luarocks.loader' not found:" error,
# then just set all the environmental variables in the script manually and
# rerun `luarocks install luarocks`, and then trigger `make test`, the
# command will pass.
