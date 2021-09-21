# ----------------------------------------------------------------------------
#
# Package       : rq
# Version       : v1.7.0
# Source repo   : https://github.com/nvie/rq
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Kishor Kunal Raj <kishore.kunal.mr@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "rq" ] ; then
  rm -rf rq
fi

# Dependency installation
dnf install -y python36 git wget gcc python36-devel procps make


# Download the repository
git clone https://github.com/nvie/rq

cd rq
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

# Clean up any previous redis-server
kill -9 `ps -ef|grep redis-server | grep -v grep |awk '{print $2}'` 2>/dev/null

# Download redis source and build
wget http://download.redis.io/releases/redis-5.0.8.tar.gz
tar xzf redis-5.0.8.tar.gz
cd redis-5.0.8
make
cd ..
cp redis-5.0.8/src/redis-server /usr/bin
ret=$?
if [ $ret -eq 0 ] ; then
 echo "Redis successfully built and installed"
else
 echo "Redis build failed"
 exit
fi
# Start redis-server
redis-server &

# Build and Test rq

pip3 install redis==3.5.0 click==7.1.2
pip3 install -r requirements.txt -r dev-requirements.txt
pip3 install -e .
ret=$?
if [ $ret -ne 0 ] ; then
 echo "dependency python pkg install failed "
 exit
else
 pytest --cov=./ --cov-report=xml --durations=5
fi
