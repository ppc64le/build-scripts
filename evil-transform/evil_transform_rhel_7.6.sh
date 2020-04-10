#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package     : evil-transform	
# Version     : master
# Source repo : https://github.com/googollee/eviltransform.git
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

git clone https://github.com/googollee/eviltransform.git evil-transform && cd evil-transform
cd ./python 

python setup.py install

