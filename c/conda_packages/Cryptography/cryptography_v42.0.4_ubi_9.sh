#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : cryptography-feedstock
# Version	 : v42.0.4
# Source repo    : https://github.com/AnacondaRecipes/cryptography-feedstock
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


mkdir crypto-test/

cd crypto-test/

#PACKAGE_NAME=cryptography
#PACKAGE_URL=https://github.com/AnacondaRecipes/cryptography-feedstock.git
#PACKAGE_VERSION=${1:-v42.0.4}


# Installing Miniconda

curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda*.sh -b -u
ln -s miniconda3/bin ~/bin


# Creating and activating conda environment

conda create -y -n crypto-test python=3.10
conda init bash
source /root/.bashrc
conda activate crypto-test


# Removing conda-forge from root/.condarc if present so that no dependencies are installed from conda-forge

if [ -f 'root/.condarc' ] &&  grep -i "conda-forge" "root/.condarc" ; then
        sed -i.bak '/conda-forge/d' "root/.condarc"
fi


# Installing git

if ! yum install -y git; then
     echo "------------------git:install_fails---------------------------------------"
     exit 1
fi


# Cloning open-ce v1.9

if ! git clone https://github.com/cdeepali/open-ce/ -b dc-cryptographyopenssldevbuild; then
     echo "------------------open-ce:clone_fails---------------------------------------"
        echo "https://github.com/cdeepali/open-ce open-ce"
        echo "open-ce  |  https://github.com/cdeepali/open-ce |  1.9 | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


# Cloning open-ce-builder v12.0.3

if ! git clone https://github.com/open-ce/open-ce-builder -b v12.0.3; then
     echo "------------------open-ce-builder:clone_fails---------------------------------------"
        echo "https://github.com/open-ce/open-ce-builder open-ce-builder"
        echo "open-ce-builder  |  https://github.com/open-ce/open-ce-builder |  12.0.3 | Linux | GitHub | Fail |  Clone_Fails"
        exit 1
fi


# Installing open-ce-builder v12.0.3

if ! pip install -e open-ce-builder; then
     echo "------------------open-ce-builder:install_fails---------------------------------------"
     exit 1
fi


# Installing conda-build

if ! conda install -y conda-build; then

     echo "------------------conda-build:install_fails---------------------------------------"
     exit 1
fi


# Building cryptography v42.0.4 .conda file

if ! open-ce build env ./open-ce/envs/cryptography-env.yaml --build_type cpu --python_versions 3.10; then

     echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
     exit 1
fi


# Listing packages prior to installing cryptography v42.0.4

conda list | grep cryptography


# Installing cryptography v42.0.4 via the .conda file

if ! conda install -y cryptography==42.0.4 -c file://crypto-test/condabuild/linux-ppc64le/; then

     echo "------------------$PACKAGE_NAME $PACKAGE_VERSION:install_fails---------------------------------------"
     exit 1
fi


# Listing packages post installing cryptography v42.0.4

conda list | grep cryptography