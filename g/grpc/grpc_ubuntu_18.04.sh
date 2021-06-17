# ----------------------------------------------------------------------------
#
# Package       : GRPC
# Version       : '1.33.2'
# Source repo   : https://github.com/grpc/grpc
# Tested on     : Ubuntu 18.04
# Script License: MIT License
# Maintainer    : Lysanne Fernandes <lysannef@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

## Install dependencies.
# Need Optional repository enabled [rhel-7-for-power-le-optional-rpms] for packages - libyaml.ppc64le libyaml-devel.ppc64le php-devel.ppc64le
sudo apt-get update -y
sudo apt-get install wget curl git autoconf libtool cmake gcc-4.8 g++-4.8 make unzip python-dev python-virtualenv openssl python-pip python3-pip python3.8 -y
sudo apt-get install zlib1g-dev  bzip2 sqlite3 libsqlite3-dev openssl libyaml-dev libyaml-0-2 -y
sudo apt-get install php php-dev golang nodejs npm -y
sudo pip install six pyyaml

# Get GRPC Source Code
cd $HOME
git clone https://github.com/grpc/grpc
cd $HOME/grpc
git submodule update --init
git checkout v1.33.2
mkdir -p cmake/build
cd cmake/build
cmake ../..
make && sudo make install

# Build protobuf
cd $HOME/grpc/third_party/protobuf
./autogen.sh && ./configure && make && sudo make install

# Build gflag
cd $HOME/grpc/third_party/gflags
mkdir build && cd build && cmake .. && make && sudo make install

export HAS_GCC=true
export HAS_CC=true
cd $HOME/grpc
$HOME/grpc/tools/run_tests/python_utils/port_server.py -p 32766 &

#Skipping tests as they take 3-4 hours for execution. Please uncomment if needed.
#Run Tests suits for C, C++,sanity php
#tools/run_tests/run_tests.py -l php -c dbg -trace
#tools/run_tests/run_tests.py -l php7 -c dbg -trace
#tools/run_tests/run_tests.py -l c++ -c dbg -trace
#tools/run_tests/run_tests.py -l sanity -c dbg -trace
#tools/run_tests/run_tests.py -l c -c dbg -trace

#Ruby Tests dependencies & test suit 
cd $HOME/grpc/third_party/zlib
./configure && make && sudo make install
cd $HOME
curl -sSL https://get.rvm.io | bash
source /usr/local/rvm/scripts/rvm
rvm -v
rvm install ruby
ruby -v
sudo apt-get install rubygems -y
gem update
sudo apt-get install ruby-dev zlib1g-dev liblzma-dev build-essential patch -y
rvm gemset list
gem install rails
sudo curl -sSL https://rvm.io/mpapis.asc | gpg --import -
sudo curl -sSL https://get.rvm.io | sudo bash -s stable --rails
source /etc/profile.d/rvm.sh
source /usr/local/rvm/scripts/rvm
sudo env PATH=$PATH gem install cocoapods -v '1.0.1'
sudo env PATH=$PATH gem install bundler
cd $HOME/grpc

#Run Tests suits for ruby
#sudo env PATH=$PATH tools/run_tests/run_tests.py -l ruby -c dbg -trace

#Python Tests dependencies & test suite

#Run Tests suits for python
#tools/run_tests/run_tests.py -l python -c dbg -trace

#Node tests dependencies & test suits

#Run Tests suits for node 
#tools/run_tests/run_tests.py -l grpc-node -c dbg -trace
