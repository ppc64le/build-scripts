# ----------------------------------------------------------------------------
#
# Package       : pyzbar
# Version       : v0.18
# Source repo   : https://github.com/NaturalHistoryMuseum/pyzbar
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
export PYZBAR_VERSION=v0.1.8
WDIR=`pwd`

#Enable EPEL, install required packages
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y epel-release-latest-7.noarch.rpm
yum update -y
yum install -y gcc gcc-c++ make autoconf git wget zbar lapack-devel atlas-devel libtool libjpeg-devel

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n pyzbar -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate pyzbar
conda install -y pytest


cd ..
git clone https://github.com/NaturalHistoryMuseum/pyzbar
cd pyzbar
git checkout ${PYZBAR_VERSION}
pip install -r requirements.pip
python setup.py install
python setup.py test

