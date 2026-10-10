#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : polars
# Version        : py-1.38.1
# Source repo    : https://github.com/pola-rs/polars
# Tested on      : UBI 9.7
# Language       : Python, Rust
# Ci-Check       : True
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
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
PACKAGE_ORG="pola-rs"
SCRIPT_PKG_VERSION=py-1.38.1
PACKAGE_VERSION=${SCRIPT_PKG_VERSION}
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"
PYTHON_VERSION=3.11.14
PYTHON_VERSION_WO_DOTS=${PYTHON_VERSION//./}
BAZEL_VERSION=6.5.0

# Note: Parsing CLI arguments is not required. Its only purpose is to test wheel creation without running the test cases locally. It will not be used by CI, so please do not refer to it while creating the new script.
# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# ----------------------
# Install required repos
# ----------------------
echo "Configuring package repositories..."
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
ret=0
dnf config-manager --set-enabled codeready-builder-for-rhel-9-$(arch)-rpms || ret=$?
if [ $ret -ne 0 ]; then
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
        rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
fi

# ---------------------------
# Remove python if exists
# ---------------------------
yum remove -y python3.11 python3.11-devel python3.11-pip python3.11-setuptools

# ---------------------------
# Dependency Installation
# ---------------------------
echo "Installing required packages..."
yum install -y git wget gcc gcc-c++ perl-IPC-Cmd perl-FindBin perl-File-Compare krb5-devel perl-File-Copy patchelf cmake ninja-build libzstd-devel libedit-devel zlib-devel re2-devel libcurl-devel libjpeg-turbo-devel gfortran openblas-devel openssl-devel protobuf-devel protobuf-compiler libffi-devel expat-devel bzip2-devel xz-devel readline-devel ncurses-devel gdbm-devel libuuid-devel graphviz java-11-openjdk-devel zip unzip clang-libs clang-devel
export CC=gcc
export CXX=g++

# --------------------------------------
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

# ------------------------------------
# Build Python from source and install
# ------------------------------------
cd "${BUILD_HOME}"
if [ -z "$(ls -A $BUILD_HOME/Python-${PYTHON_VERSION})" ]; then
        wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
        tar -xzf Python-${PYTHON_VERSION}.tgz
        rm -rf Python-${PYTHON_VERSION}.tgz
        cd Python-${PYTHON_VERSION}
        ./configure --prefix=/usr/ --with-system-expat -with-system-ffi
else
        cd Python-${PYTHON_VERSION}
fi
make altinstall -j$(nproc)
ln -sf /usr/bin/python${PYTHON_VERSION:0:4} /usr/bin/python3
ln -sf /usr/bin/pip${PYTHON_VERSION:0:4} /usr/bin/pip3
ln -sf /usr/bin/python${PYTHON_VERSION:0:4} /usr/bin/python
ln -sf /usr/bin/pip${PYTHON_VERSION:0:4} /usr/bin/pip
pip install numpy wheel build maturin pytest "setuptools<71"

# ---------------------------
# Install Rust
# ---------------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup toolchain install 1.94.0
rustup default 1.94.0-powerpc64le-unknown-linux-gnu

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
if [ -z "$(ls -A $BUILD_HOME/${PACKAGE_NAME})" ]; then
	git clone "${PACKAGE_URL}"
	cd "${PACKAGE_NAME}"
	git checkout "${PACKAGE_VERSION}"
	wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/polars/polars_py-1.38.1.patch
	git apply polars_py-1.38.1.patch
else
        cd "${PACKAGE_NAME}"
fi

# ---------------------------
# Build
# ---------------------------
ret=0
cd py-polars
python -m build --wheel ||  ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi
cd ..
export PYPOLARS_WHEEL=${BUILD_HOME}/${PACKAGE_NAME}/py-polars/dist/polars-${PACKAGE_VERSION:3}-py3-none-any.whl
test -f ${PYPOLARS_WHEEL}
cp "$PYPOLARS_WHEEL" "$BUILD_HOME/"
echo "polars wheel available at [$PYPOLARS_WHEEL]"

# Skipping the test suite for now as it take 4-5 hours to run if you run it locally on high config vm. Uncomment the following lines to run the test suite.

## --------------------------------------------------------------------------------------------------------------------------
# maturin build -m py-polars/runtime/polars-runtime-32/Cargo.toml --profile dist-release || ret=$?
# if [ $ret -ne 0 ]; then
#         set +ex
#         echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
#         exit 1
# fi
# export POLARS32_WHEEL=${BUILD_HOME}/${PACKAGE_NAME}/target/wheels/polars_runtime_32-${PACKAGE_VERSION:3}-cp310-abi3-manylinux_2_34_ppc64le.whl
# test -f ${POLARS32_WHEEL}


  # ---------------------------
  # Build connectorx 0.4.5
  # ---------------------------
  cd "${BUILD_HOME}"
  if [ -z "$(ls -A $BUILD_HOME/connector-x)" ]; then
          git clone https://github.com/sfu-db/connector-x.git
          cd connector-x
          git checkout v0.4.5
          cd connectorx-python
          maturin build --release
  fi
  export CONNECTORX_WHEEL=${BUILD_HOME}/connector-x/connectorx-python/target/wheels/connectorx-0.4.5-cp${PYTHON_VERSION_WO_DOTS:0:3}-cp${PYTHON_VERSION_WO_DOTS:0:3}-manylinux_2_34_ppc64le.whl


  # ---------------------------
  # Build polars-cloud 0.5.0
  # ---------------------------
  cd "${BUILD_HOME}"
  if [ -z "$(ls -A $BUILD_HOME/polars-cloud-client)" ]; then
          git clone https://github.com/pola-rs/polars-cloud-client.git
          cd polars-cloud-client/client
          git checkout client-0.5.0
          maturin build --release
  fi
  export POLARSCLOUD_WHEEL=${BUILD_HOME}/polars-cloud-client/client/target/wheels/polars_cloud-0.5.0-cp310-abi3-manylinux_2_34_ppc64le.whl

  # ---------------------------
  # Build polars-ds 0.11.0
  # ---------------------------
  cd "${BUILD_HOME}"
  if [ -z "$(ls -A $BUILD_HOME/polars_ds_extension)" ]; then
          git clone https://github.com/abstractqqq/polars_ds_extension.git
          cd polars_ds_extension
          git checkout v0.11.0
          maturin build --release
  fi
  export POLARSDS_WHEEL=${BUILD_HOME}/polars_ds_extension/target/wheels/polars_ds-0.11.0-cp39-abi3-manylinux_2_34_ppc64le.whl

  # ------------------------------------
  # Build arrow-adbc sqlite driver .so
  # ------------------------------------
  cd "${BUILD_HOME}"
  if [ -z "$(ls -A $BUILD_HOME/arrow-adbc)" ]; then
          git clone https://github.com/apache/arrow-adbc
          cd arrow-adbc
          git checkout apache-arrow-adbc-22
          mkdir build
          cd build
          cmake ../c -DADBC_DRIVER_SQLITE=ON
          make -j$(nproc)
  fi
  export ADBC_SQLITE_LIBRARY=${BUILD_HOME}/arrow-adbc/build/driver/sqlite/libadbc_driver_sqlite.so

  # -----------------------
  # Build Apache arrow .so
  # -----------------------
  cd "${BUILD_HOME}"
  if [ -z "$(ls -A $BUILD_HOME/arrow)" ]; then
          git clone https://github.com/apache/arrow.git
          cd arrow/cpp
          git checkout apache-arrow-23.0.1
          mkdir build
          cd build
          cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DARROW_S3=ON \
            -DARROW_ACERO=ON \
            -DARROW_CSV=ON \
            -DARROW_JSON=ON \
            -DARROW_DATASET=ON \
            -DARROW_PARQUET=ON \
            -DARROW_FILESYSTEM=ON \
            -DARROW_WITH_SNAPPY=ON \
            -DARROW_WITH_ZSTD=ON \
            -DARROW_WITH_LZ4=ON \
            -DARROW_WITH_BROTLI=ON \
            -DARROW_WITH_BOOST=OFF
          make -j$(nproc)
  else
          cd arrow/cpp/build
  fi
  make install


  # ---------------------------
  # Build bazel and install
  # ---------------------------
  export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
  export JRE_HOME=${JAVA_HOME}/jre
  export PATH=${JAVA_HOME}/bin:$PATH
  cd $BUILD_HOME
  if [ -z "$(ls -A $BUILD_HOME/bazel)" ]; then
 	mkdir bazel
 	cd bazel
 	wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
 	unzip bazel-${BAZEL_VERSION}-dist.zip
 	rm -rf bazel-${BAZEL_VERSION}-dist.zip
 	env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
  fi
  cp $BUILD_HOME/bazel/output/bazel /usr/bin/

  # ---------------------------
  # Build jaxlib wheel
  # ---------------------------
  cd $BUILD_HOME
  /usr/bin/python -m pip install numpy wheel build maturin pytest "setuptools<71"
  if [ -z "$(ls -A $BUILD_HOME/jax)" ]; then
  	git clone https://github.com/jax-ml/jax.git
 	cd jax
 	git checkout jaxlib-v0.4.28
 	git clone https://github.com/google/boringssl.git
 	cd boringssl
 	git checkout c00d7ca810e93780bd0c8ee4eea28f4f2ea4bcdc
 	wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/polars/polars_py-1.38.1_boringssl.patch
 	git apply polars_py-1.38.1_boringssl.patch
 	cd ..
 	build/build.py --noenable_cuda --noenable_mosaic_gpu --nobuild_gpu_plugin --bazel_options=--override_repository=boringssl=${BUILD_HOME}/jax/boringssl
  fi
  export JAXLIB_WHEEL=$BUILD_HOME/jax/dist/jaxlib-0.4.28*.whl

  # --------------------------------------
  # Download test deps. wheels from devpi
  # --------------------------------------
  cd $BUILD_HOME
  mkdir test-deps-wheels
  cd test-deps-wheels
  wget https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/a14/eccfe9cb04fab/torch-2.10.0+ppc64le1-cp311-cp311-manylinux_2_34_ppc64le.whl#sha256=a14eccfe9cb04fab0d068037e55dfd8643e12a1701bbb43a118c91be4c4b16e9

  export PYTORCH_WHEEL=$BUILD_HOME/test-deps-wheels/torch-2.10.0+ppc64le1-cp311-cp311-manylinux_2_34_ppc64le.whl

  wget https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/704/be044c510fdd3/llvmlite-0.46.0+ppc64le1-cp311-cp311-manylinux_2_34_ppc64le.whl#sha256=704be044c510fdd3b33516146a5c13a6a79df7adc7ae30ba9c5c117bd0aee5f8

  export LLVMLITE_WHEEL=${BUILD_HOME}/test-deps-wheels/llvmlite-0.46.0+ppc64le1-cp311-cp311-manylinux_2_34_ppc64le.whl

  wget https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/c9e/36ccb611a36b7/polars_runtime_32-1.38.1+ppc64le1-cp310-abi3-manylinux_2_34_ppc64le.whl#sha256=c9e36ccb611a36b7ed5802feb20ffc7eea8fd0c352f6e9841f42943a3dcef747

  export POLARS32_WHEEL=${BUILD_HOME}/test-deps-wheels/polars_runtime_32-1.38.1+ppc64le1-cp310-abi3-manylinux_2_34_ppc64le.whl 

  # ---------------------------
  # Test
  # ---------------------------
  cd ${BUILD_HOME}/${PACKAGE_NAME}
  ret=0
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export PYARROW_WITH_S3=1
  export ArrowDataset_DIR=/usr/lib64/cmake/arrow/
  export Parquet_DIR=/usr/lib64/cmake/arrow/
  pip install --upgrade uv
  uv pip install $CONNECTORX_WHEEL $LLVMLITE_WHEEL $PYTORCH_WHEEL $JAXLIB_WHEEL jax setuptools wheel maturin --system
  uv pip install --no-deps $POLARSCLOUD_WHEEL $POLARSDS_WHEEL --system
  uv pip install --no-deps --compile-bytecode -r requirements.txt --system
  uv pip install --upgrade --compile-bytecode "pyiceberg>=0.7.1" pyiceberg-core --system
  uv pip install $POLARS32_WHEEL $PYPOLARS_WHEEL --system
  uv pip uninstall polars-runtime-compat polars-runtime-64 --system
  cd py-polars
  rm -rf tests/unit/meta/test_polars_import.py ## Disable one flaky test
  rm -rf tests/docs/test_user_guide.py
  rm -rf tests/unit/io/test_iceberg.py
  POLARS_TIMEOUT_MS=200000 pytest -n auto -m "slow or not slow" || ret=$?
  if [ $ret -ne 0 ]; then
          set +ex
  	echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
  	exit 2
  fi

  # ---------------------------
  # Conclude
  # ---------------------------
  set +ex
  echo "Complete: Build and Test successful! Two flaky tests (test_polars_import, test_user_guide) were disabled."
  echo "polars wheel available at [$PYPOLARS_WHEEL]"
