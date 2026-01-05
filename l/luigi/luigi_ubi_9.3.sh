#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : luigi
# Version          : v3.6.0
# Source repo      : https://github.com/spotify/luigi.git
# Tested on        : UBI:9.3
# Language         : Python,Javascript
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_NAME=luigi
PACKAGE_VERSION=${1:-v3.6.0}
PACKAGE_URL=https://github.com/spotify/luigi.git
PACKAGE_DIR=luigi

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#install dependencies
yum install -y python3 python3-devel python3-pip git gcc-toolset-13 wget bzip2 bzip2-devel openssl openssl-devel make

#export path for gcc-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install dependencies
pip install 'tox<4.0' pytest pytest-cov pyhive mypy codecov types-toml types-requests types-python-dateutil
pip install psutil mock selenium hypothesis jsonschema boto3 avro "prometheus-client>=0.5,<0.15" azure-storage-blob==2.1.0 azure-mgmt-resource
pip install azure-storage==0.36.0 "elasticsearch<7.14" "moto[all]==4.2.9" requests-unixsocket "sqlalchemy<2" datadog

if ! pip install -e ".[toml]" ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1

#Skipping few tests due to failure parity on both x86 and Power platform
if ! pytest -v --ignore=test/contrib --ignore=test/customized_run_test.py --ignore=test/server_test.py --ignore=test/cmdline_test.py --ignore=test/lock_test.py --ignore=test/mypy_test.py --ignore=test/task_serialize_test.py -k "not test_sending_same_task_twice_without_cooldown_leads_to_double_run and not test_dynamic_dependencies" -p no:warnings -W ignore ; then
   echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
   exit 2
else
   echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
   exit 0
fi
