#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package     : demjson	
# Version     : release-2.2.4
# Source repo : https://github.com/dmeranda/demjson.git
# Tested on   : RHEL 7.6
# Maintainer  : Amol Patil <amol.patil2@ibm.com>
#
# Disclaimer  : This script has been tested in non-root mode on given
# ==========    platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -e

sudo yum clean all
sudo yum -y update

sudo yum install -y rh-python36-python.ppc64le git 

source scl_source enable rh-python36
pip install 2to3

git clone https://github.com/dmeranda/demjson.git demjson && cd demjson
git checkout release-2.2.4

2to3 -w test/test_demjson.py

python setup.py install
python setup.py test


