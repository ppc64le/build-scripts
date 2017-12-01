# ----------------------------------------------------------------------------
#
# Package       : GRPC
# Version       : '1.7.2'
# Source repo   : https://github.com/grpc/grpc
# Tested on     : RHEL 7.3
# Script License: MIT License
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
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
sudo yum update -y
sudo yum install -y wget git autoconf libtool cmake gcc-c++ make unzip python-devel python-virtualenv.noarch which openssl-devel
sudo yum install -y zlib-devel bzip2-devel sqlite sqlite-devel openssl-devel libyaml.ppc64le libyaml-devel.ppc64le
sudo yum install -y php-devel.ppc64le php.ppc64le
sudo easy_install pip
sudo pip install six pyyaml

#Install Go
cd $HOME
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Get GRPC Source Code
cd $HOME
git clone https://github.com/grpc/grpc
cd $HOME/grpc
git submodule update --init
make && sudo make install
# One more way to compile the GRPC
#mkdir build && cd $HOME/grpc/build && cmake .. && make && sudo make install

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

#Run Tests suits for C, C++,sanity php 
tools/run_tests/run_tests.py -l php -c dbg -trace
tools/run_tests/run_tests.py -l php7 -c dbg -trace
tools/run_tests/run_tests.py -l c++ -c dbg -trace
tools/run_tests/run_tests.py -l sanity -c dbg -trace
tools/run_tests/run_tests.py -l c -c dbg -trace

#Ruby Tests dependencies & test suit 
cd $HOME/grpc/third_party/zlib
./configure && make && sudo make install
cd $HOME
sudo curl -sSL https://rvm.io/mpapis.asc | gpg --import -
sudo curl -sSL https://get.rvm.io | sudo bash -s stable --rails
source /etc/profile.d/rvm.sh
source /usr/local/rvm/scripts/rvm
sudo env PATH=$PATH gem install cocoapods -v '1.0.1'
sudo env PATH=$PATH gem install bundler
cd $HOME/grpc
#Run Tests suits for ruby
sudo env PATH=$PATH tools/run_tests/run_tests.py -l ruby -c dbg -trace

#Python Tests dependencies & test suit
cd $HOME
wget https://www.python.org/ftp/python/3.4.5/Python-3.4.5.tgz
tar -xvf Python-3.4.5.tgz
cd $HOME/Python-3.4.5
./configure && make && sudo make install
cd $HOME/grpc
#Run Tests suits for python
tools/run_tests/run_tests.py -l python -c dbg -trace

#Node tests dependencies & test suits
cd $HOME
git clone https://github.com/nodejs/node.git node
cd $HOME/node && git checkout v6.2.1 && ./configure && make && sudo make install
cd $HOME/grpc
#Run Tests suits for node 
tools/run_tests/run_tests.py -l grpc-node -c dbg -trace

