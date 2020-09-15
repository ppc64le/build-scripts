# ----------------------------------------------------------------------------
#
# Package               :       CouchDB
# Version               :       2.3
# Source repo           :       https://github.com/apache/couchdb/
# Tested on             :       ubuntu_16.04
# Script License        :       Apache License, Version 2 or later
# Maintainer            :       Sarvesh Tamba <sarvesh.tamba@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#             Tested CouchDB v2.3(current master) with Erlang v21 and Elixir v1.8 only.
#
# ----------------------------------------------------------------------------
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

if [ $# -ne 3 ]; then
    echo "Usage:- ./couchdb_ubuntu_16.04.sh <COUCHDB_GITHUB_BRANCH> <ERLANG_GITHUB_BRANCH> <ELIXIR_GITHUB_BRANCH>"
    echo "Example:- ./couchdb_ubuntu_16.04.sh \"master\" \"maint-21\" \"v1.8\""
    exit
fi

COUCHDB_GITHUB_BRANCH=$1
ERLANG_GITHUB_BRANCH=$2
ELIXIR_GITHUB_BRANCH=$3

#Install dependencies
sudo apt-get update -y
sudo apt-get install -y autoconf gcc make sed libncurses5-dev libncursesw5-dev \
        libcurl4-openssl-dev xsltproc fop openssl libxml2-utils python-wxgtk3.0 \
        python-wxgtk3.0-dev openssl libssl-dev default-jre default-jdk g++ \
        python-wxgtk-media3.0 unixodbc-dev libwxgtk3.0-dev default-jdk libutil-freebsd-dev \
        wget build-essential pkg-config libicu-dev libmozjs185-dev python3-pip help2man \
        xz-utils python3-venv locales libmozjs-24-0v5 libmozjs-24-bin git curl \
        python3-requests python3-sphinx shunit2

WDIR=$HOME/couchdb_install

sudo locale-gen en_US.UTF-8

echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

#Clone and Build Erlang (Tested v21)
mkdir $WDIR
cd $WDIR
git clone -b $ERLANG_GITHUB_BRANCH https://github.com/erlang/otp.git
cd otp
./otp_build autoconf
./configure
make
sudo make install
cd ../

#Clone and Build Elixir (Tested 1.8)
git clone -b $ELIXIR_GITHUB_BRANCH https://github.com/elixir-lang/elixir.git
cd elixir
make clean test
#Set required environment variables
export LD_LIBRARY_PATH="/$WDIR/elixir/lib/:$LD_LIBRARY_PATH"
export PATH="/$WDIR/elixir/bin/:$PATH"
cd ../

#Clone and Build Couchdb (Tested v2.3 current master)
sudo pip3 install sphinx
sudo pip3 install --upgrade sphinx_rtd_theme nose requests hypothesis
wget https://nodejs.org/dist/v12.3.1/node-v12.3.1-linux-ppc64le.tar.xz
tar -xvf node-v12.3.1-linux-ppc64le.tar.xz
#Set required environment variables
export LD_LIBRARY_PATH="/$WDIR/node-v12.3.1-linux-ppc64le/lib/:$LD_LIBRARY_PATH"
export PATH="/$WDIR/node-v12.3.1-linux-ppc64le/bin/:$PATH"

git clone -b $COUCHDB_GITHUB_BRANCH https://github.com/apache/couchdb.git
cd couchdb
./configure --dev
make release
#workaround
cd src/docs && make man && cd ../../
make release
make check
cd ../