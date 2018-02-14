# ----------------------------------------------------------------------------
#
# Package	: exgrid
# Version	: 1.0.0
# Source repo	: https://github.com/bradleyd/exgrid
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum install -y openssl openssl-devel ncurses-devel ncurses unixODBC \
  unixODBC-devel make which java-1.8.0-openjdk-devel.ppc64le tar gcc wget git

cd $HOME

# Download erlang to install erl and escript binaries
wget http://erlang.org/download/otp_src_20.0.tar.gz
tar xvzf otp_src_20.0.tar.gz
cd otp_src_20.0
rm -rf ../otp_src_20.0.tar.gz

export ERL_TOP=`pwd` && export PATH=$PATH:$ERL_TOP/bin

#Configure and build erlang
./configure && sudo make && sudo make install
cd ..

sudo localedef -i en_US -f UTF-8 en_US.UTF-8
export LC_ALL="en_US.UTF-8"

#Building Elixir
git clone https://github.com/elixir-lang/elixir.git
cd elixir
make clean test
make install
cd ..

#Clone and Build exgrid
git clone https://github.com/bradleyd/exgrid.git
cd exgrid
export MIX_ENV=test
mix local.rebar --force
mix local.hex --force
mix deps.get
mix test
