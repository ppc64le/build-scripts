#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : zeromq-feedstock
# Version	 : v4.3.5
# Source repo    : https://github.com/AnacondaRecipes/zeromq-feedstock
# Tested on	 : UBI 9
# Language       : Bash
# Travis-Check   : TRUE
# Script License : Apache License, Version 2 or later
# Maintainer	 : Stacey Ferreira <Stacey.Ferreira@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


mkdir zeromq_updated/

cd zeromq_updated/

PACKAGE_NAME=zeromq-feedstock
PACKAGE_URL=https://github.com/AnacondaRecipes/zeromq-feedstock.git
PACKAGE_VERSION=${1:-v4.3.5}


# Installing Miniconda

curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda*.sh -b -u
ln -s miniconda3/bin ~/bin


# Creating and activating conda environment

conda create -y -n zeromq-test python=3.10
conda init bash
source /root/.bashrc
conda activate zeromq-test


# Removing conda-forge from root/.condarc if present so that no dependencies are installed from conda-forge

if [ -f 'root/.condarc' ] &&  grep -i "conda-forge" "root/.condarc" ; then
        sed -i.bak '/conda-forge/d' "root/.condarc"
fi


# Installing git

if ! yum install -y git; then
     echo "------------------git:install_fails---------------------------------------"
     exit 1
fi


# Cloning open-ce v1.10.0

if ! git clone -q https://github.com/open-ce/open-ce -b open-ce-v1.10.0; then
     echo "------------------open-ce:clone_fails---------------------------------------"
        echo "https://github.com/open-ce/open-ce open-ce"
        echo "open-ce  |  https://github.com/open-ce/open-ce |  1.10.0 | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


# Cloning open-ce-builder v13.0.0

if ! git clone -q https://github.com/open-ce/open-ce-builder -b v13.0.0; then
     echo "------------------open-ce-builder:clone_fails---------------------------------------"
        echo "https://github.com/open-ce/open-ce-builder open-ce-builder"
        echo "open-ce-builder  |  https://github.com/open-ce/open-ce-builder |  13.0.0 | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


# Installing open-ce-builder v13.0.0

if ! pip install -e open-ce-builder; then
     echo "------------------open-ce-builder:install_fails---------------------------------------"
     exit 1
fi


# Cloning zeromq v4.3.5

if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
     echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


cd $PACKAGE_NAME


# Modifying zeromq version present in /recipe/meta.yaml

if ! sed -i.bak 's/{% set version = "4.3.4" %}/{% set version = "4.3.5" %}/g' "./recipe/meta.yaml"; then

     echo "------------------meta.yaml file:file_modification_fails---------------------------------------"
     exit 1
fi


# Installing conda-build

if ! conda install -y conda-build; then

     echo "------------------conda-build:install_fails---------------------------------------"
     exit 1
fi


# Installing dependencies for zeromq

if ! yum install -y libxcrypt-compat; then

     echo "------------------libxcrypt-compat:install_fails---------------------------------------"
     exit 1
fi


# Building zeromq v4.3.5 .conda file

if ! open-ce build feedstock --python_version=3.10 --conda_build_config=../open-ce/envs/conda_build_config.yaml --output_folder=../output; then

     echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
     exit 1
fi


# Listing packages prior to installing zeromq v4.3.5

conda list | grep zeromq


# Installing zeromq v4.3.5 via the .conda file

if ! conda install -y zeromq==4.3.5 -c file://zeromq_updated/output/; then

     echo "------------------l$PACKAGE_NAME $PACKAGE_VERSION:install_fails---------------------------------------"
     exit 1
fi


# Listing packages post installing zeromq v4.3.5

conda list | grep zeromq