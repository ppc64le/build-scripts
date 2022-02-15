#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: ruamel.ordereddict
# Version	: 0.4.15
# Source repo	: https://github.com/ruamel/ordereddict
# Tested on	: UBI8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation Gajanan Kulkarni <gajanan.kulkarni@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export PACKAGE_NAME=ordereddict
export PACKAGE_VERSION=0.4.15
export PACKAGE_URL=https://github.com/ruamel/ordereddict


git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
yum install python2 python2-pip gcc python2-devel -y
ln -sf /usr/bin/python2 /usr/bin/python
dnf install redhat-rpm-config -y
python setup.py install
python ./test/unit/test_dict.py