#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : pillow-feedstock
# Version	 : v10.2.0
# Source repo    : https://github.com/AnacondaRecipes/pillow-feedstock
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


mkdir pillow_updated/

cd pillow_updated/

PACKAGE_NAME=pillow-feedstock
PACKAGE_URL=https://github.com/AnacondaRecipes/pillow-feedstock.git
PACKAGE_VERSION=${1:-v10.2.0}


# Installing Miniconda

curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda*.sh -b -u
ln -s miniconda3/bin ~/bin


# Creating and activating conda environment

conda create -y -n pillow-test python=3.10
conda init bash
source /root/.bashrc
conda activate pillow-test


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


# Cloning pillow v10.2.0

if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
     echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


cd $PACKAGE_NAME


# Modifying pillow version (if required) present in /recipe/meta.yaml (Update the second occurrence of package version number)

#if ! sed -i.bak 's/{% set version = "10.2.0" %}/{% set version = "10.2.0" %}/g' "./recipe/meta.yaml"; then

#     echo "------------------meta.yaml file:file_modification_fails---------------------------------------"
#     exit 1
#fi


# Installing conda-build

if ! conda install -y conda-build; then

     echo "------------------conda-build:install_fails---------------------------------------"
     exit 1
fi


# Building pillow v10.2.0 .conda file

if ! open-ce build feedstock --python_version=3.10 --conda_build_config=../open-ce/envs/conda_build_config.yaml --output_folder=../output; then

     echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
     exit 1
fi


# Listing packages prior to installing pillow v10.2.0

conda list | grep pillow


# Installing pillow v10.2.0 via the .conda file

if ! conda install -y pillow==10.2.0 -c file://pillow_updated/output/; then

     echo "------------------l$PACKAGE_NAME $PACKAGE_VERSION:install_fails---------------------------------------"
     exit 1
fi


# Listing packages post installing pillow v10.2.0

conda list | grep pillow