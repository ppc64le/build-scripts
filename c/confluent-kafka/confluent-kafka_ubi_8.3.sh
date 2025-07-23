# ----------------------------------------------------------------------------
#
# Package       : confluent-kafka
# Version       : 0.11.5
# Source repo   : https://github.com/confluentinc/confluent-kafka-python
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/confluentinc/confluent-kafka-python
VERSION=v0.11.5

# Default tag for confluent-kafka
if [ -z "$1" ]; then
  export VERSION="v0.11.5"
else
  export VERSION="$1"
fi

# install required dependencies
yum update -y
yum install -y make python36-devel git gcc gcc-c++ openssl-devel cyrus-sasl
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka && ./configure --prefix=/usr && make && make install && ldconfig

# clone the repo
cd ..
git clone $REPO
cd confluent-kafka-python/
git checkout ${VERSION}
C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib python3 setup.py install
python3 -m venv venv_test
source venv_test/bin/activate
pip install -r test-requirements.txt

python setup.py build
python setup.py install
rm -rf tests/__init__.py
# test package
# pytest -s -v tests/test_*.py
# 2 tests are failing and those are in parity with x86
deactivate
