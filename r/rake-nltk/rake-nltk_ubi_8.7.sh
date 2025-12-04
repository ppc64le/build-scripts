#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : rake-nltk
# Version       : a80f633
# Source repo   : https://github.com/csurfer/rake-nltk
# Tested on     : UBI 8.7
# Language      : python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijeet Dandekar <Abhijeet.Dandekar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rake-nltk
PACKAGE_VERSION=${1:-a80f633}
PACKAGE_URL=https://github.com/csurfer/${PACKAGE_NAME}.git
wdir=`pwd`

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel
yum search wget
yum install -y wget

export PATH=${PATH}:$HOME/conda/bin
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda install https://anaconda.org/anaconda/python/3.7.4/download/linux-ppc64le/python-3.7.4-h2bede3c_1.tar.bz2

cd $wdir

if ! git clone $PACKAGE_URL ; then
    echo "------------------$PACKAGE_NAME:clone_fails----------------------"
    	exit 1
fi

cd ${PACKAGE_NAME}

git checkout ${PACKAGE_VERSION}

pip3 install -r requirements.txt
ret=0

python3 setup.py build || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "------------------$PACKAGE_NAME:build_fails-----------------------" 
  exit 1
fi

python3 setup.py install || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "------------------$PACKAGE_NAME:install_fails---------------------" 
  exit 1
fi

python3 -m pip install --upgrade pip

yum install -y redhat-rpm-config gcc libffi-devel python3-devel \
    openssl-devel cargo pkg-config
pip install cryptography --no-binary cryptography
pip3 install poetry

poetry install

poetry run python -c "import nltk; nltk.download('stopwords')"

if ! poetry run tox; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    exit 2
fi

set +ex
echo "Build and tests Successful!"
