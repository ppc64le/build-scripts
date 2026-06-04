#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : couchbase-python-client
# Version       : 4.6.1
# Source repo   : https://github.com/couchbase/couchbase-python-client
# Tested on     : UBI:9.7
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Mohammed Sheikh <Mohammed.Sheikh1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

WORKDIR=$(pwd)
PACKAGE_NAME=couchbase-python-client
PACKAGE_VERSION=${1:-4.6.1}
PACKAGE_DIR=couchbase-python-client
PACKAGE_URL=https://github.com/couchbase/couchbase-python-client

# Installing system dependencies
yum install -y git gcc gcc-c++ make cmake openssl-devel python3.12 python3.12-devel python3.12-pip python3.12-setuptools python3.12-wheel zlib-devel perl-core ninja-build

# Cloning the repository
git clone --depth 1 --branch ${PACKAGE_VERSION} --recurse-submodules ${PACKAGE_URL}

cd ${PACKAGE_NAME}

# Installing dependencies
python3.12 -m pip install -r dev_requirements.txt

# Set CPM cache
PYCBC_SET_CPM_CACHE=ON PYCBC_USE_OPENSSL=ON python3.12 setup.py configure_ext

# Build the SDK and wheel
PYCBC_USE_OPENSSL=ON python3.12 setup.py build_ext --inplace

PYCBC_USE_OPENSSL=ON python3.12 -m pip install . --no-binary couchbase --no-build-isolation

# Validate the installation
python3.12 -P -c "import couchbase; print('Version:', couchbase.__version__)"

echo "---------- $PACKAGE_NAME-$PACKAGE_VERSION Installation completed ----------"

# skipping test cases as they require a live running cluster 
# change the configuration inside tests/test_config.ini folder
# [realserver]
# ; Set this to true if there is a real cluster available
# enabled = True
# #Local
# host = localhost
# port = 8091
# admin_username = Administrator
# ; The administrative password. This is the password used to
# ; log into the admin console
# admin_password = password
# bucket_name = default
# ; If a SASL bucket is being used (i.e. buckets are set up
# ; per the script, then this is the *bucket* password
# ; bucket_password sasl_password
# bucket_password = password

# test 
# python3.12 -m pytest -m pycbc_couchbase -p no:asyncio -v -p no:warnings

# failed test cases are in parity with x86
exit 0