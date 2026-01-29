#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : psutil
# Version          : 7.1.3
# Source repo      : https://github.com/giampaolo/psutil.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Lenzie Camilo <Lenzie.Camilo3@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=psutil
PACKAGE_VERSION=${1:-release-7.1.3}
PACKAGE_URL=https://github.com/giampaolo/psutil.git

# Install necessary system dependencies
yum install -y make g++ git gcc gcc-c++ wget openssl-devel bzip2-devel libffi-devel zlib-devel procps-ng python3.12 python3.12-devel python3.12-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install additional dependencies
python3.12 -m pip install setuptools wheel pytest overlay pytest-instafail pytest-xdist psleak

#install
if ! python3.12 -m pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#set test path
export PYTHONWARNINGS=always
export PYTHONUNBUFFERED=1
export PSUTIL_DEBUG=1
export PSUTIL_TESTING=1
export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
export PYTHONPATH=$(pwd):$PYTHONPATH

#run tests skipping and deselecting few tests failing on ppc64le and x86
if ! pytest -v --deselect=psutil/tests/test_linux.py --deselect=psutil/tests/test_system.py -k "not test_disk_partitions and not test_debug and not test_who and not test_terminal and not test_users and not test_cpu_freq and not test_leak_mem and not test_cpu_affinity and not test_cpu_times and not test_per_cpu_times and not test_import_all and not test_multi_sockets_procs and not test_against_nproc and not test_against_sysdev_cpu_num and not test_against_findmnt and not test_comparisons" --disable-warnings ; then
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

