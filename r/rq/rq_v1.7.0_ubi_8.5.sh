#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: rq
# Version	: v1.7.0
# Source repo	: https://github.com/nvie/rq/
# Tested on	: UBI: 8
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik / Vedang Wartikar<Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rq
PACKAGE_VERSION=${1:-v1.7.0}
PACKAGE_URL=https://github.com/nvie/rq

yum install -y python36 git wget gcc python36-devel procps make

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget http://download.redis.io/releases/redis-5.0.8.tar.gz
tar xzf redis-5.0.8.tar.gz
cd redis-5.0.8
make

cd ..
cp redis-5.0.8/src/redis-server /usr/bin
redis-server &

pip3 install redis==3.5.0
pip3 install click==7.1.2
pip3 install -r dev-requirements.txt
pip3 install -e .

pytest --cov=./ --cov-report=xml --durations=5