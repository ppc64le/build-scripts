# ----------------------------------------------------------------------------
#
# Package       : aniso8601
# Version       : v8.0.0
# Source repo   : https://bitbucket.org/nielsenb/aniso8601/src/master/
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
export PACKAGE_VERSION=v8.0.0
WDIR=`pwd`

yum update -y
yum install -y gcc gcc-c++ make autoconf git wget libtool

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n aniso8601 -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate aniso8601

git clone https://bitbucket.org/nielsenb/aniso8601/src/master/
cd master
git checkout ${PACKAGE_VERSION}
python setup.py install
python setup.py test
