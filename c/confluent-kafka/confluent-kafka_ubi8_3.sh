# ----------------------------------------------------------------------------
#
# Package       : confluent-kafka
# Version       : 1.7.0
# Source repo   : https://github.com/confluentinc/confluent-kafka-python
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y
yum install -y make python36-devel git gcc gcc-c++ openssl-devel cyrus-sasl
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka && ./configure --prefix=/usr && make && make install && ldconfig
cd..
git clone https://github.com/confluentinc/confluent-kafka-python.git
cd confluent-kafka-python/
git checkout $PACKAGE_VERSION
C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib python3 setup.py install
python3 -m venv venv_test
source venv_test/bin/activate
pip install -r tests/requirements.txt
python setup.py build
python setup.py install
pytest -s -v tests/test_*.py
deactivate
