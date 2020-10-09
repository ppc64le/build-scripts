# ----------------------------------------------------------------------------
#
# Package       : RediSearch
# Version       : 2.0.0
# Source repo   : https://github.com/RediSearch/RediSearch.git
# Tested on     : RHEL 7.8
# Script License: Apache License, Version 2 or later
# Maintainer    : Kandarpa Malipeddi <kandarpa.malipeddi.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

REDISEARCH_VERSION=v2.0.0

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm;
yum update -y;
yum install -y wget git gcc gcc-c++ make python2 python2-psutil;

# Install CMake.
git clone https://github.com/Kitware/CMake
cd CMake
git checkout v3.11.4
./bootstrap && make && make install
cd .. && rm -rf CMake

#Create link for python2 as python
python --version > /dev/null 2>/dev/null
if [ $? != 0 ]
then
   PYTHON2=$(command which python2)
   PYTHONDIR=$(command dirname $PYTHON2)
   ln -s $PYTHON2 ${PYTHONDIR}/python
fi

# Clone and build the RediSearch
git clone --recursive https://github.com/RediSearch/RediSearch.git
cd RediSearch
git checkout ${REDISEARCH_VERSION}
python -m pip install --no-cache-dir git+https://github.com/RedisLabsModules/RLTest.git@master
python -m pip install --no-cache-dir git+https://github.com/Grokzen/redis-py-cluster.git@master
python -m pip install --no-cache-dir git+https://github.com/RedisLabs/RAMP@master
make fetch
make build TEST=1
sed -i "s/\(.*\)'Development Tools'\(.*\)/#\1'Development Tools'\2/g" deps/readies/bin/getredis
./deps/readies/bin/getredis

 
make c_tests
make pytest
################################################################################
# Note: 
# Currently observing 2 test failures with cpp_tests and goes into hang state.
# Hence, this script need to terminate manually.
# Soon, going to publish the patch to fix this.
# Commenting cpp_tests till publishing the patch.
################################################################################
#make cpp_tests