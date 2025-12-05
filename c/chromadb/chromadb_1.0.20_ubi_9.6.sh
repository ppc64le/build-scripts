#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : chromadb
# Version       : 1.0.20
# Source repo   : https://github.com/chroma-core/chroma
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache 2.0 license
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_DIR=chroma
PACKAGE_NAME=chromadb
PACKAGE_VERSION=${1:-1.0.20}
PACKAGE_URL=https://github.com/chroma-core/chroma.git
WORKDIR=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

PROTOC_VERSION=31.1

# Install dependencies.
yum -y install gcc g++ cmake autoconf unzip make git python3.11 python3.11-pip python3.11-devel
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
yum clean metadata

export PATH="/root/.cargo/bin:$PATH"

PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-ppcle_64.zip
curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/$PROTOC_ZIP
unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
rm -f $PROTOC_ZIP
chmod +x /usr/local/bin/protoc && \
protoc --version  # Verify installed version

python3.11 -m pip install --upgrade maturin cffi patchelf setuptools wheel build

cd $WORKDIR

# Clone the chroma source
git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}
git submodule update --init --recursive
# Apply patch
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_ubi_9.6.patch

# Install the chromadb requirements.
python3.11 -m pip install -r requirements.txt --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux

cargo update generator@0.8.1
cargo update generator@0.7.5

# Build and install chromadb
if ! python3.11 -m pip install .; then
        echo "------------------$PACKAGE_NAME:build_install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_install_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

cd $WORKDIR

# Test wheel after installation

# Install OpenBLAS library and sqlite3 library files
yum install openblas-devel -y

# Build and install the required sqlite2 library (Ref: https://github.com/coleifer/pysqlite3#building-a-statically-linked-library)
yum install wget -y
wget https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=release -O sqlite.tar.gz
tar xzf sqlite.tar.gz
cd sqlite/
./configure
make sqlite3.c
cd $WORKDIR
git clone https://github.com/coleifer/pysqlite3.git
cp sqlite/sqlite3.[ch] pysqlite3/
cd pysqlite3
python3.11 setup.py build_full
rm -f /usr/lib64/libsqlite3.so.0
ln -s $WORKDIR/pysqlite3/build/lib.linux-ppc64le-cpython-311/pysqlite3/_sqlite3.cpython-311-powerpc64le-linux-gnu.so /usr/lib64/libsqlite3.so.0

python3.11 -c "import chromadb; print(chromadb.__version__)"
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
