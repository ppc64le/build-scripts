# ----------------------------------------------------------------------------
#
# Package       : pymongo
# Version       : 3.10.1
# Source repo   : https://github.com/mongodb/mongo-python-driver
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PATH=${PATH}:$HOME/conda/bin
export PYTHON_VERSION=3.6
export LANG=en_US.utf8
export LD_LIBRARY_PATH=/usr/local/lib
export PYMONGO_VERSION=3.10.1
WDIR=`pwd`

yum update -y
yum install -y gcc gcc-c++ make autoconf git wget libtool

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n pymongo -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate pymongo

git clone https://github.com/mongodb/mongo-python-driver
cd mongo-python-driver
git checkout ${PYMONGO_VERSION}
python setup.py install
python setup.py test
