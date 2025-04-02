#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : vision
# Version          : v0.16.2
# Source repo      : https://github.com/pytorch/vision
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=vision
PACKAGE_VERSION=${1:-v0.16.2}
PACKAGE_URL=https://github.com/pytorch/vision
PACKAGE_DIR=vision

echo "---------------------------------------------Installing dependency-------------------------------------------------------"
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

echo "---------------------------------------------Installing dependency-------------------------------------------------------"
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
echo "---------------------------------------------Installing dependency-------------------------------------------------------"
yum install -y python python-devel python-pip git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  
yum install -y libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel epel-release meson ninja-build 
echo "---------------------------------------------Installing dependency-------------------------------------------------------"
yum install -y gcc-gfortran  libomp-devel zip unzip sqlite-devel cmake openblas-devel cmake gcc-gfortran
yum install -y libjpeg-devel zlib-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel

export LD_LIBRARY_PATH=/usr/lib64/libopenblas.so.0:$LD_LIBRARY_PATH

echo "---------------------------------------------Installing dependency-------------------------------------------------------"
dnf groupinstall -y "Development Tools"

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

echo "---------------------------------------------Installing dependency via pip-------------------------------------------------------"
pip install wheel scipy ninja build pytest
echo "---------------------------------------------Installing dependency via pip-------------------------------------------------------"
pip install "numpy<2.0"

#install pytorch
echo "---------------------------------------------Cloning pytorch-------------------------------------------------------"
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.1.2
echo "---------------------------------------------Installing pytorch-------------------------------------------------------"
git submodule sync
git submodule update --init --recursive
echo "---------------------------------------------Installing requirements-------------------------------------------------------"
pip install -r requirements.txt

echo "---------------------------------------------Downloading patch-------------------------------------------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/python-ecosystem/p/pytorch/pytorch_v2.0.1.patch
git apply ./pytorch_v2.0.1.patch
echo "---------------------------------------------Installing pytorch-------------------------------------------------------"
python setup.py install
cd ..

# Clone the repository
echo "---------------------------------------------Cloning vision-------------------------------------------------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install necessary Python packages
echo "---------------------------------------------Installing dependency via pip-------------------------------------------------------"
pip install setuptools  meson meson-python 
echo "---------------------------------------------Installing dependency via pip-------------------------------------------------------"
pip install cython  
echo "---------------------------------------------Installing dependency via pip-------------------------------------------------------"
pip install pytest-mock pytest-xdist pytest-timeout

#Install
echo "---------------------------------------------Installing vision-------------------------------------------------------"
if ! (pip install . --no-build-isolation) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
# skipping few test modules as they take more time to execute and skipped "test_draw_boxes" as it is in parity with x86
echo "---------------------------------------------Testing vision-------------------------------------------------------"
if !(pytest -v test/ --dist=loadfile -n 1 -p no:warnings --ignore=test/test_backbone_utils.py --ignore=test/test_models.py --ignore=test/test_transforms.py --ignore=test/test_transforms_v2_functional.py -k "not test_draw_boxes" ); then
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

