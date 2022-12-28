#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jupyter-base-notebook
# Version	: v7.0.0a9
# Source repo	: https://github.com/jupyter/notebook.git
# Tested on	: UBI: 8.5
# Language      : Go 
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jupyter-base-notebook
PACKAGE_VERSION=${1:-v7.0.0a9}
PACKAGE_URL=https://github.com/jupyter/notebook.git


yum -y update && yum install -y wget yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake
npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn

npm i -g corepack
corepack prepare yarn@stable --activate
pip3 install webpack
 
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh
chmod +x Miniconda3-latest-Linux-ppc64le.sh
./Miniconda3-latest-Linux-ppc64le.sh
export PATH=/root/miniconda3/bin:$PATH
   
//restart shell
 
conda install jupyter  -y
jupyter labextension install jupyterlab-tabular-data-editor
conda install -c conda-forge jupyterlab=3 jupyter-packaging cookiecutter -y
conda install -c conda-forge mamba -y
mamba create -n notebook -c conda-forge python nodejs -y
mamba init

//restart shell 

mamba activate notebook

wget https://static.rust-lang.org/dist/rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.65.0-powerpc64le-unknown-linux-gnu
./install.sh
cd ..

git clone  $PACKAGE_URL
cd notebook
git checkout $PACKAGE_VERSION
pip install -e ".[dev,test]"
jlpm develop
jupyter server extension enable notebook
if ! jlpm build; then
	echo "Build fails"
	exit 2
fi

if ! jlpm run build:test; then
	echo "Test building fails"
	exit 2
fi

if ! jlpm run test; then
	echo "Test fails"
	exit 2
else
	echo "Build and test successful"
	exit 0
fi