#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : confluent-kafka
# Version           : v2.10.0
# Source repo       : https://github.com/confluentinc/confluent-kafka-python.git
# Tested on         : UBI:9.3
# Language          : Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=confluent-kafka-python
PACKAGE_VERSION=${1:-v2.10.0}
PACKAGE_URL=https://github.com/confluentinc/confluent-kafka-python.git
PACKAGE_DIR=confluent-kafka-python
CURRENT_DIR="${PWD}"

yum install -y make python3 python3-pip python3-devel git wget cmake openssl openssl-devel cyrus-sasl gcc-toolset-13 java-21-openjdk-devel gcc-toolset-13-gcc-c++

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#build and install librdkafka
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
./configure --prefix=/usr
make
make install
ldconfig
cd ..

#clone pckg
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install dependencies
pip install pytest wheel avro

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases 
if ! pytest -s -v -k 'not test_kafkaError_unknonw_error' tests/test_*.py ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
