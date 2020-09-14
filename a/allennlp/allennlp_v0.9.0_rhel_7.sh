# ----------------------------------------------------------------------------
#
# Package       : allennlp
# Version       : v0.9.0
# Source repo   : https://github.com/allenai/allennlp
# Tested on     : RHEL 7.6
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
export ALLENNLP_VERSION="v0.9.0"
export PATH=${PATH}:$HOME/conda/bin
export PYTHON_VERSION=3.6
export LANG=en_US.utf8
export WDIR=`pwd`

package_name=devtoolset-7
isinstalled=$(rpm -q $package_name)
if [ !  "$isinstalled" == "package $package_name is not installed" ];then
        #Install conda
        wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
        sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
        conda config --add channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le
        $HOME/conda/bin/conda update -y -n base conda
        conda create -n allennlp -y python=${PYTHON_VERSION}
        conda init bash
        eval "$(conda shell.bash hook)"
        conda activate allennlp
        conda install -y -c "conda-forge" pytorch h5py scikit-learn cudatoolkit-dev cmake make

        #add libcuda path
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/conda/envs/allennlp/lib/stubs/

        python -m pip install pip==9.0.3 && python -m pip install cython pytest mock jsonschema numpy

        #Install blis from source code
        export BLIS_ARCH='generic'

        # install Spacy from source code
        git clone https://github.com/explosion/spaCy -b v2.1.9 && cd spaCy
        git clone https://github.com/explosion/cython-blis -b v0.2.4 && cd cython-blis
        wget https://patch-diff.githubusercontent.com/raw/explosion/cython-blis/pull/7.diff && git apply 7.diff
        cython blis/*.pyx && python setup.py install && cd ../
        cp -rf $HOME/conda/envs/allennlp/lib/python3.6/site-packages/numpy/core/include/numpy/* include/numpy/.
        python -m pip install -r requirements.txt
        python setup.py install && cd ../

        # Spacy installation ends

        # Senetnce piece does not get installed via pip, hence needs to be installed manually
        git clone https://github.com/google/sentencepiece.git -b v0.1.83 && cd sentencepiece
        mkdir build && cd build && cmake ..&& make -j $(nproc) && make install && ldconfig -v
        export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:`pwd`
        cd ../python && python setup.py install && cd ../../

        git clone https://github.com/allenai/allennlp -b ${ALLENNLP_VERSION}
        cd allennlp

        #Apply test Patch
        git apply ${WDIR}/allennlp_tests_fix_and_skip_patch.patch

        #Build and test
        python -m pip install --editable .
        allennlp test-install
else
        # Spacy installation begins
        yum install -y yum-utils
        yum-config-manager repos --enable rhel-7-for-power-le-optional-rpms --enable rhel-7-server-for-power-le-rhscl-rpms

        #Install the required dependencies
        yum install -y python3 python3-devel python3-pip git wget openssh-server java-1.8.0-openjdk bzip2 \
                devtoolset-7 devtoolset-7-gcc devtoolset-7-gcc-c++

        scl enable devtoolset-7 ./allennlp_rhel_7.6.sh
fi
