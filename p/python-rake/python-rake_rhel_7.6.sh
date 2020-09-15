# ----------------------------------------------------------------------------
#
# Package       : python-rake
# Version       : master
# Source repo   : https://github.com/csurfer/rake-nltk
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryan D'Mello <ryan.dmello1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PYTHON=python3
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=master
export PACKAGE_NAME=python-rake
export PACKAGE_URL=https://github.com/csurfer/rake-nltk

yum update -y
yum install -y yum-utils
yum-config-manager --enable rhel-7-for-power-le-optional-rpms
yum install -y python3 python3-devel python3-pip git wget
${PYTHON} -m pip install nltk

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda config --add channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le
conda install -y -c "conda-forge" tensorflow

${PYTHON} setup.py install
${PYTHON} setup.py test

# Test python rake installation
