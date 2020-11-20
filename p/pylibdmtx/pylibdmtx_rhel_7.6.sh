# ----------------------------------------------------------------------------
#
# Package       : pylibdmtx
# Version       : v0.18
# Source repo   : https://github.com/NaturalHistoryMuseum/pylibdmtx.git
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
export PYLIBDMTX_VERSION=v0.1.9
WDIR=`pwd`

yum update -y
yum install -y gcc gcc-c++ make autoconf git wget lapack-devel atlas-devel libtool

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n pylibdmtx -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate pylibdmtx
conda install -y pytest
conda install -y -c https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le numpy

git clone https://github.com/dmtx/libdmtx
cd libdmtx/
sh autogen.sh
./configure
make
make install

cd ..
git clone https://github.com/NaturalHistoryMuseum/pylibdmtx.git
cd pylibdmtx/
git checkout ${PYLIBDMTX_VERSION}
pip install -r requirements.pip
python setup.py install
python setup.py test

