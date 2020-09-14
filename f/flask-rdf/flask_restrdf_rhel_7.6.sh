# ----------------------------------------------------------------------------
#
# Package       : flask_restrdf
# Version       : v0.2.1
# Source repo   : https://github.com/hufman/flask_rdf
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
export FLASK_RESTRDF_VERSION=v0.2.1
WDIR=`pwd`
yum update -y
yum install -y git wget python36

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n flask_restrdf -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate flask_restrdf
git clone https://github.com/hufman/flask_rdf
cd flask_rdf
git checkout $FLASK_RESTRDF_VERSION

pip install -r requirements.txt
pip install -r requirements.test.txt
python setup.py install
nosetests