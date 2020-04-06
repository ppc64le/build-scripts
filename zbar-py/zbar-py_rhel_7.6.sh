# ----------------------------------------------------------------------------
#
# Package       : zbar-py
# Version       : master
# Source repo   : https://github.com/zplab/zbar-py
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
WDIR=`pwd`

yum update -y
yum install -y gcc gcc-c++ make autoconf git wget

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n zbar-py -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate zbar-py
conda install -y -c "https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le" numpy
conda install -y pytest

git clone  https://github.com/zplab/zbar-py
cd zbar-py
python setup.py install
#No tests found
