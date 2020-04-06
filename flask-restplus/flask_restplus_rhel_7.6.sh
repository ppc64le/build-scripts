# ----------------------------------------------------------------------------
#
# Package       : flask_restplus
# Version       : 0.13.0
# Source repo   : https://github.com/noirbizarre/flask-restplus
# Tested on     : RHEL 7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
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
export FLASK_RESTPLUS_VERSION=0.13.0
WDIR=`pwd`

yum update -y
yum install -y git wget python36

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n flask_restplus -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate flask_restplus
conda install -y flask werkzeug=0.16.0

git clone https://github.com/noirbizarre/flask-restplus
cd flask-restplus
git checkout $FLASK_RESTPLUS_VERSION
python setup.py install
python setup.py test

