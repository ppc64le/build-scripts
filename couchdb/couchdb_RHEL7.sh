# ----------------------------------------------------------------------------
#
# Package               :       CouchDB
# Version               :       2.3
# Source repo           :       https://github.com/apache/couchdb/
# Tested on             :       Red Hat Enterprise Linux Server 7.7 (Maipo)
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

if [ $# -ne 3 ]; then
    echo "Usage:- ./couchdb_RHEL7.sh <COUCHDB_GITHUB_BRANCH> <ERLANG_GITHUB_BRANCH> <ELIXIR_GITHUB_BRANCH>"
    echo "Example:- ./couchdb_RHEL7.sh \"master\" \"maint-21\" \"v1.8\""
    exit
fi

COUCHDB_GITHUB_BRANCH=$1
ERLANG_GITHUB_BRANCH=$2
ELIXIR_GITHUB_BRANCH=$3

#Install dependencies
sudo yum update -y
sudo yum install -y autoconf autoconf-archive automake help2man git make wget patch zip \
    ncurses-devel java-devel curl-devel libicu-devel libtool rh-nodejs10-nodejs-devel python-devel\
    unixODBC-devel openssl-devel perl-Test-Harness rh-python36-python-pip rh-python36-python-devel gcc-c++

#Set required variables
WDIR=$HOME/couchdb_install
export PATH="/opt/rh/rh-python36/root/usr/bin/:/opt/rh/rh-nodejs10/root/usr/bin/:$PATH"

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

#Clone and Build Mozilla SpiderMonkey 1.8.5
wget http://ftp.mozilla.org/pub/js/js185-1.0.0.tar.gz
tar -xvf js185-1.0.0.tar.gz
cd js-1.8.5/js/src/
curl -SL https://bug638056.bmoattachments.org/attachment.cgi?id=520157 -o bug638056_mozilla_cacheFlush.diff
patch -i bug638056_mozilla_cacheFlush.diff
./configure --host=ppc64le
make
sudo make install
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
cd ../../../

#Clone and Build Couchdb (Tested v2.3 current master)
pip3 install sphinx
pip3 install --upgrade sphinx_rtd_theme nose requests hypothesis
git clone -b $COUCHDB_GITHUB_BRANCH https://github.com/apache/couchdb.git
cd couchdb
./configure -c
make release ERL_CFLAGS="-I/usr/local/include/js -I/usr/local/lib/erlang/usr/include" ERL_LDFLAGS="/usr/local/lib"
make check ERL_CFLAGS="-I/usr/local/include/js -I/usr/local/lib/erlang/usr/include" ERL_LDFLAGS="/usr/local/lib"
cd ../
