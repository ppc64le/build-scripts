# ----------------------------------------------------------------------------
#
# Package       : cChardet
# Version       : 2.1.6
# Source repo   : https://github.com/PyYoshi/cChardet
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
export cChardet_VERSION=2.1.6
export TOXENV=py36
WDIR=`pwd`

yum update -y
yum install -y gcc gcc-c++ make autoconf git wget libtool

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n cChardet -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate cChardet
pip install tox

git clone https://github.com/PyYoshi/cChardet
cd cChardet
git checkout ${cChardet_VERSION}
sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules
git submodule update --init --recursive
pip install -r requirements-dev.txt
tox -e $TOXENV
