#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : vision
# Version          : v0.15.2
# Source repo      : https://github.com/pytorch/vision
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
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
PACKAGE_VERSION=${1:-v0.15.2}
PACKAGE_URL=https://github.com/pytorch/vision
PACKAGE_DIR=vision

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
yum install -y python-devel python-pip git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel epel-release meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel

export LD_LIBRARY_PATH=/usr/lib64/libopenblas.so.0:$LD_LIBRARY_PATH

dnf groupinstall -y "Development Tools"

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

#install pytorch
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
pip install -r requirements.txt
git submodule update --init --recursive
python3 setup.py install
cd ..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install necessary Python packages
pip install wheel setuptools pytest build meson meson-python ninja cython pillow pytest-mock pytest-xdist pytest-timeout
pip install "numpy<2"

#Install
if ! (pip install . --no-build-isolation) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
# skipping few test modules as they take more time to execute and skipped "test_draw_boxes" as it is in parity with x86
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


