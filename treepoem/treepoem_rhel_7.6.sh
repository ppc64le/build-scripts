# ----------------------------------------------------------------------------
#
# Package       : treepoem
# Version       : v3.3.1
# Source repo   : https://github.com/adamchainz/treepoem.git 
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

#Install required dependencies
yum update -y
yum install -y gcc gcc-c++ make autoconf git wget libjpeg-turbo-devel libpng-devel tar gzip libffi-devel openssl-devel

wget https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs952/ghostscript-9.52.tar.gz
tar -zxvf ghostscript-9.52.tar.gz
cd ghostscript-9.52
rm -rf libpng 
sh autogen.sh
./configure
make
make install

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n treepoem -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate treepoem
conda install -y pytest

git clone https://github.com/adamchainz/treepoem.git
cd treepoem
pip install -r requirements/py36.txt
python setup.py install
pip install tox
tox -e py36

