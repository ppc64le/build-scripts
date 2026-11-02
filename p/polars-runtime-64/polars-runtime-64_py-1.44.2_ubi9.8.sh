#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : polars-runtime-64
# Version        : py-1.44.2
# Source repo    : https://github.com/pola-rs/polars
# Tested on      : UBI 9.8
# Language       : Python, Rust
# Ci-Check       : True
# Maintainer     : Pratik Tonage <Pratik.Tonage@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------


# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="polars"
PACKAGE_VERSION=${1:-py-1.44.2}
PACKAGE_URL="https://github.com/pola-rs/polars"
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME="$(pwd)"


# ---------------------------
# Install system dependencies
# ---------------------------

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256

yum install -y python3.12 python3.12-pip python3.12-devel make
yum install -y \
    binutils cmake git wget curl-minimal \
    gcc gcc-c++ openblas-devel openssl-devel protobuf-devel clang-libs clang-devel \
    perl-IPC-Cmd perl-FindBin perl-File-Compare perl-File-Copy \
    krb5-devel patchelf ninja-build libzstd-devel libedit-devel zlib-devel re2-devel bzip2-devel xz-devel \
    libcurl-devel libjpeg-turbo-devel gfortran  protobuf-compiler libffi-devel expat-devel \
    readline-devel ncurses-devel gdbm-devel libuuid-devel graphviz zip unzip 

export CC=gcc
export CXX=g++

# Install sqlite 3.51.3 from source
# --------------------------------------
cd "${BUILD_HOME}"

if [ -z "$(ls -A $BUILD_HOME/sqlite-autoconf-3510300)" ]; then
    wget https://sqlite.org/2026/sqlite-autoconf-3510300.tar.gz
    tar -xzf sqlite-autoconf-3510300.tar.gz
    rm -rf sqlite-autoconf-3510300.tar.gz
    cd sqlite-autoconf-3510300
    ./configure --prefix=/usr/
    make -j$(nproc)
else
    cd sqlite-autoconf-3510300
fi

make install
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

cd "${BUILD_HOME}"

# Install Python build tools
python3.12 -m pip install numpy wheel build maturin pytest setuptools

# ---------------------------
# Install Rust
# ---------------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version
cargo --version

# ---------------------------
# Clone and Prepare Repository
# ---------------------------

if [ -z "$(ls -A $BUILD_HOME/${PACKAGE_NAME})" ]; then
    git clone "${PACKAGE_URL}"
    cd "${PACKAGE_NAME}"
    git checkout "${PACKAGE_VERSION}"
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/polars/polars_py-1.44.2.patch
    git apply polars_py-1.44.2.patch    
else
    cd "${PACKAGE_NAME}"
fi

# ---------------------------
# Build
# ---------------------------

if ! maturin build -m py-polars/runtime/polars-runtime-64/Cargo.toml --profile dist-release; then
    echo "------------------$PACKAGE_NAME:Build_Failed-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Failed"
    exit 1
fi

export POLARS64_WHEEL=${BUILD_HOME}/${PACKAGE_NAME}/target/wheels/polars_runtime_64-1.44.2-cp310-abi3-manylinux_2_34_ppc64le.whl
test -f ${POLARS64_WHEEL}
cp "$POLARS64_WHEEL" "$BUILD_HOME/"

echo "polars_runtime_64 wheel available at [$POLARS64_WHEEL]"

#Tests are temporarily disabled because the full test suite takes approximately
#4–5 hours to run locally, even on a high-spec VM. Several dependencies
#(JAXlib, ConnectorX, DuckDB, and polars-ds) require source builds because
#compatible wheels are not yet available on Devpi.
#Separate build scripts are available for these dependencies.
#Testing will be re-enabled once the required wheels are available on Devpi.

# # ---------------------------
# # Build polars-cloud 0.11.3
# # ---------------------------
# cd "${BUILD_HOME}"
# if [ -z "$(ls -A $BUILD_HOME/polars-cloud-client)" ]; then
#         git clone https://github.com/pola-rs/polars-cloud-client.git
#         cd polars-cloud-client/client
#         git checkout client-0.11.3
#         maturin build --release
# fi
# export POLARSCLOUD_WHEEL=${BUILD_HOME}/polars-cloud-client/client/target/wheels/polars_cloud-0.11.3-cp310-abi3-manylinux_2_34_ppc64le.whl

# # ------------------------------------
# # Build arrow-adbc sqlite driver .so
# # ------------------------------------
# cd "${BUILD_HOME}"
# if [ -z "$(ls -A $BUILD_HOME/arrow-adbc)" ]; then
#         git clone https://github.com/apache/arrow-adbc
#         cd arrow-adbc
#         git checkout apache-arrow-adbc-24
#         mkdir build
#         cd build
#         cmake ../c -DADBC_DRIVER_SQLITE=ON
#         make -j$(nproc)
# fi
# export ADBC_SQLITE_LIBRARY=${BUILD_HOME}/arrow-adbc/build/driver/sqlite/libadbc_driver_sqlite.so

# # -----------------------
# # Build Apache arrow .so
# # -----------------------
# cd "${BUILD_HOME}"
# if [ -z "$(ls -A $BUILD_HOME/arrow)" ]; then
#         git clone https://github.com/apache/arrow.git
#         cd arrow/cpp
#         git checkout apache-arrow-23.0.1
#         mkdir build
#         cd build
#         cmake .. \
#           -DCMAKE_BUILD_TYPE=Release \
#           -DCMAKE_INSTALL_PREFIX=/usr \
#           -DARROW_S3=ON \
#           -DARROW_ACERO=ON \
#           -DARROW_CSV=ON \
#           -DARROW_JSON=ON \
#           -DARROW_DATASET=ON \
#           -DARROW_PARQUET=ON \
#           -DARROW_FILESYSTEM=ON \
#           -DARROW_WITH_SNAPPY=ON \
#           -DARROW_WITH_ZSTD=ON \
#           -DARROW_WITH_LZ4=ON \
#           -DARROW_WITH_BROTLI=ON \
#           -DARROW_WITH_BOOST=OFF
#         make -j$(nproc)
# else
#         cd arrow/cpp/build
# fi
# make install

# # ---------------------------
# # Test
# # ---------------------------
# cd ${BUILD_HOME}/${PACKAGE_NAME}
# ret=0
# export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
# export PYARROW_WITH_S3=1
# export ArrowDataset_DIR=/usr/lib64/cmake/arrow/
# export Parquet_DIR=/usr/lib64/cmake/arrow/
# pip install --upgrade uv
# uv pip install jax setuptools wheel maturin --system
# uv pip install --no-deps $POLARSCLOUD_WHEEL --system 
# uv pip install --only-binary :all: --no-cache-dir \
#     polars-runtime-32==1.44.2 \
#     connectorx==0.4.6 \
#     jaxlib==0.4.28 \
#     polars_ds==0.11.0 \
#     torch==2.12.0+ppc64le1 \
#     llvmlite==0.46.0+ppc64le1 \
#     duckdb==1.5.7.dev1 \
#     matplotlib \
#     --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
#     --system
# uv pip install --no-deps --compile-bytecode -r requirements.txt --system
# uv pip install --system --compile-bytecode multimark nokap duckdb-engine
# uv pip install --system \
#   "librt>=0.16.0" "ast-serialize>=0.11.2,<1.0.0" "tinycss2>=1.2.1" "grpc-stubs>=1.24.7,<2.0.0" "sqlalchemy==2.0.54" \
#   "properdocs>=1.6.5" "nh3" "panel-material-ui>=0.10.0" "sphinx-last-updated-by-git" "encutils" "formulaic>=1.1.0"
# uv pip install --upgrade --compile-bytecode "pyiceberg>=0.7.1" pyiceberg-core!=0.9.0 --system
# uv pip install $PYPOLARS_WHEEL --system
# uv pip uninstall polars-runtime-compat polars-runtime-64 --system
# cd py-polars
# POLARS_TIMEOUT_MS=200000 pytest -n auto -m "(slow or not slow) and not debug" || ret=$?
# if [ $ret -ne 0 ]; then
#         set +ex
# 	echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
# 	exit 2
# fi

# # ---------------------------
# # Conclude
# # ---------------------------
# set +ex
# echo "Complete: Build and Test successful!"
# echo "polars_runtime_64 wheel available at [$POLARS64_WHEEL]"
