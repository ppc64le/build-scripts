#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: onnx
# Version	: v1.6.0 v1.8.1
# Source repo	: https://github.com/onnx/onnx
# Tested on	: ubi 8.5
# Language      : Python
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="onnx"
PACKAGE_VERSION=${1:-"v1.9.0"}
PACKAGE_URL="https://github.com/onnx/onnx"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR="$PWD"

echo "installing... "
dnf install -qy git cmake gcc-c++ make wget bzip2
export PB_VERSION=2.6.1
function install_protobuf() {
	# Install protobuf
	local pb_dir="$HOME/.cache/pb"
	mkdir -p "$pb_dir"
	wget -qO- "https://github.com/google/protobuf/releases/download/v${PB_VERSION}/protobuf-${PB_VERSION}.tar.gz" | tar -xz -C "$pb_dir" --strip-components 1
	cd "$pb_dir" && ./configure && make -j"${NUMCORES}" && make check && make install && ldconfig && make install && cd -
}

#installing mini conda
wget -q https://repo.anaconda.com/miniconda/Miniconda3-py38_4.8.2-Linux-ppc64le.sh
export CONDA_PREFIX="/conda"
bash Miniconda3-py38_4.8.2-Linux-ppc64le.sh -b -p $CONDA_PREFIX
$CONDA_PREFIX/bin/conda init
source ~/.bashrc

echo "cloning..."
if ! git clone -q $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/${PACKAGE_NAME}
git checkout "$PACKAGE_VERSION"
git submodule update --init --recursive
pip install pytest nbval

cd "$HOME_DIR"/$PACKAGE_NAME/third_party/pybind11
cmake -Bbuild
cmake --install build
cd - && install_protobuf
cmake -Bbuild && cmake --build build
cmake --install build

if ! pip install .; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! pytest; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
