# ----------------------------------------------------------------------------
#
# Package       : flask_restful
# Version       : 0.3.8
# Source repo   : https://github.com/flask-restful/flask-restful
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
export FLASK_RESTFUL_VERSION=0.3.8
WDIR=`pwd`

yum update -y
yum install -y git wget python36

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n flask_restful -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate flask_restful
conda install -y flask nose werkzeug=0.16.0

git clone https://github.com/flask-restful/flask-restful
cd flask-restful
git checkout $FLASK_RESTFUL_VERSION
python setup.py install
python setup.py test

