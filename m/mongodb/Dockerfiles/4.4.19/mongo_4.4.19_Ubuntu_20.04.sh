#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package	: mongo
# Version	: 4.4.19
# Source repo	: https://github.com/mongodb/mongo.git
# Tested on	: Ubuntu 20.04
# Language      : C++
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

CWD=$(pwd)
MONGO_VERSION==${1:-4.4.19}

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates jq numactl procps unzip git build-essential wget ca-certificates libcurl4-openssl-dev libssl-dev python3-dev python3-pip scons python3-pip wget gnupg dirmngr lzma-dev libunwind-dev tzdata
mkdir -p mongodb-src-r${MONGO_VERSION}
cd mongodb-src-r${MONGO_VERSION}
git clone https://github.com/mongodb/mongo.git
cd mongo
git checkout r${MONGO_VERSION}
python3 -m pip install -r etc/pip/compile-requirements.txt
python3 -m pip install -r etc/pip/dev-requirements.txt
python3 buildscripts/scons.py install-all --separate-debug=on --disable-warnings-as-errors DESTDIR=/usr/ --ssl=on --no-cache --release
python3 buildscripts/resmoke.py run --suite unittests,unittests_auth,unittests_client,unittests_query,unittests_repl,unittests_sharding
