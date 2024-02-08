#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : rake-nltk
# Version       : a80f633
# Source repo   : https://github.com/csurfer/rake-nltk
# Tested on     : UBI 8.7
# Language      : python
# Travis-Check  : True
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
PACKAGE_VERSION=a80f633
PACKAGE_URL=https://github.com/csurfer/${PACKAGE_NAME}.git
wdir=`pwd`

#Install dependencies
yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel
yum search wget
yum install -y wget

#install python3.7 using conda
export PATH=${PATH}:$HOME/conda/bin
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda install https://anaconda.org/anaconda/python/3.7.4/download/linux-ppc64le/python-3.7.4-h2bede3c_1.tar.bz2


#Download source code
cd $wdir
# git clone ${PACKAGE_URL}

# New part
if ! git clone $PACKAGE_URL ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    	exit 1
fi

cd ${PACKAGE_NAME}

# checkout to latest commit instaed of latest release as releases are not there.
git checkout ${PACKAGE_VERSION}



pip3 install -r requirements.txt
ret=0

# Build step for a Python project
python3 setup.py build || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "FAIL: Build failed."
  exit 1
fi

# Install step for a Python project
python3 setup.py install || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "FAIL: Install failed."
  exit 1
fi

#tests
python3 -m pip install --upgrade pip

dnf install -y redhat-rpm-config gcc libffi-devel python3-devel \
    openssl-devel cargo pkg-config
pip install cryptography --no-binary cryptography
pip3 install poetry



# Install Project Dependencies and Create Virtual Environment
poetry install

poetry run python -c "import nltk; nltk.download('stopwords')"
# Run Tests with Tox
poetry run tox
# tox is a tool for managing and running test environments often used for testing python projects
# with different python versions and dependencies


pip install pre-commit
#pre commit is a framework for managing and maintaining multi language pre commit hooks.
#Hooks are scripts that run before each commit to perform checks and ensure code quality.

pre-commit run --all-files
# Runs pre-commit hooks on all files in the repository.

poetry run sphinx-build -b html docs/ docs/_build/html
# Builds documentation using Sphinx.
# Sphinx build is a command line tool used for documentation generation.
# This command generates HTML documentation from source files in docs/ directory and places
# output in docs/_build/html

poetry export --dev --without-hashes -f requirements.txt > requirements.txt
# Exports projects dependencies including development dependencies into requirements.txt file.

poetry run pytest
# Used for running tests using pytest testing framework.poetry uses its virtual envoronment to 
#  execute pytest command this ensures correct version of dependencies specified in your pyproject.toml file.

#Conclude
set +ex
echo "Build and tests Successful!"
