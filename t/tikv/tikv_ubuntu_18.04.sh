# ----------------------------------------------------------------------------
#
# Package	: tikv
# Version	: v0.3.0-beta
# Source repo	: https://github.com/tikv/tikv
# Tested on	: ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#Install dependencies
sudo apt-get update -y
sudo apt-get install -y build-essential cmake gcc g++ make git curl wget zlib1g-dev
sudo curl https://sh.rustup.rs -sSf | sh

export PATH=$PATH:$HOME/.cargo/bin
export GOROOT=/tmp/go
export ROCKSDB_SYS_SSE=0
export AFL_NO_X86=1

cd /tmp
wget https://dl.google.com/go/go1.11.4.linux-ppc64le.tar.gz
tar -zxvf go1.11.4.linux-ppc64le.tar.gz
sudo cp -r go/bin/* /usr/bin

curl -L https://github.com/gflags/gflags/archive/v2.1.2.tar.gz -o gflags.tar.gz
tar xf gflags.tar.gz
cd gflags-2.1.2
cmake .
make
sudo make install

cd $HOME
git clone https://github.com/tikv/tikv.git
cd tikv
git checkout v3.0.0-beta
git cherry-pick -x 98f06ee10b65dd38931e76cff490fc193b31de50

make build
make test
