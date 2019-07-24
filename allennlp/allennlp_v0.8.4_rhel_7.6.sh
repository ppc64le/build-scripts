# ----------------------------------------------------------------------------
#
# Package       : allennlp
# Version       : v0.8.4
# Source repo   : https://github.com/allenai/allennlp
# Tested on     : docker.io/nvidia/cuda-ppc64le:10.1-cudnn7-devel-centos7, RHEL 7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export IBM_POWERAI_LICENSE_ACCEPT=yes
export ALLENNLP_VERSION="v0.8.4"
export PATH=${PATH}:$HOME/conda/bin
export PYTHON_VERSION=3.6
export LANG=en_US.utf8
WDIR=`pwd`

#Install the required dependencies
sudo yum install -y git vim wget openssh-server gcc gcc-c++ java-1.8.0-openjdk bzip2 make

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n allennlp -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate allennlp

git clone https://github.com/allenai/allennlp
cd allennlp
git checkout ${ALLENNLP_VERSION}
conda install -y -c "https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le" \
	-c "conda-forge"  pytorch spacy h5py scikit-learn

#Apply Patch
git apply ${WDIR}/awscli_spacy_testfix.patch

#Build and test
pip install --editable .
allennlp test-install
