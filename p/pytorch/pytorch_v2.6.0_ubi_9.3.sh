#!/usr/bin/bash -i
# -----------------------------------------------------------------
#
# Package	        : pytorch
# Version	        : v2.6.0
# Source repo	    : https://github.com/pytorch/pytorch
# Tested on	        : UBI 9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=pytorch
SCRIPT_PACKAGE_VERSION=main
PACKAGE_VERSION=v2.6.0
PACKAGE_URL=https://github.com/pytorch/pytorch
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME=$(pwd)
export _GLIBCXX_USE_CXX11_ABI=1

# Update and install dependencies
yum update -y && yum install -y wget git cmake clang ninja-build bzip2 gcc-toolset-13

# Install gcc 13
source /opt/rh/gcc-toolset-13/enable
gcc --version

# Installing Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
if command -v rustc &>/dev/null; then
    echo "Rust installed successfully!"
    rustc --version
else
    echo "Rust installation failed."
fi

# Install Miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
chmod +x Miniconda3-latest-Linux-ppc64le.sh
./Miniconda3-latest-Linux-ppc64le.sh -u -b -p /root/miniconda3
rm -rf Miniconda3-latest-Linux-ppc64le.sh
~/miniconda3/bin/conda init

source ~/.bashrc
conda --version
python --version
conda deactivate

conda create -n pytorch_env -y
conda activate pytorch_env
conda install cmake ninja pip -y

# Download Pytorch
git clone --single-branch --branch ${PACKAGE_VERSION} ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt

# Build Pytorch
if ! (MAX_JOBS=$(nproc) python setup.py bdist_wheel && pip install dist/*.whl); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cd ..
# Pytorch print report
pip install pytest
if ! ( pytest $PACKAGE_NAME/test/test_utils.py) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi