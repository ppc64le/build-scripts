#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ray
# Version          : ray-2.47.1
# Source repo      : https://github.com/ray-project/ray
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ray
PACKAGE_VERSION=${1:-ray-2.47.1}
PACKAGE_URL=https://github.com/ray-project/ray
PACKAGE_DIR=ray/python
PYSPY_VERSION=v0.3.14
ARROW_VERSION=16.1.0
BAZEL_VERSION=6.5.0

CURRENT_DIR=${PWD}

yum install -y git make pkgconfig zip unzip cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel libxml2-devel libxslt-devel openssl-devel libyaml-devel patch perl libxcrypt-compat procps bzip2

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > sh.rustup.rs && \
sh ./sh.rustup.rs -y && export PATH=$PATH:$HOME/.cargo/bin && . "$HOME/.cargo/env"

#Install bazel
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $CURRENT_DIR

# Install py-spy
git clone https://github.com/benfred/py-spy -b ${PYSPY_VERSION}
cd py-spy && cargo install py-spy
pip install --upgrade maturin
maturin build --release -o dist
pip install dist/py_spy*_ppc64le.whl
cd $CURRENT_DIR

# Install utf8proc
git clone https://github.com/JuliaStrings/utf8proc.git
cd utf8proc
make -j$(nproc)
make install
ldconfig
cd $CURRENT_DIR

#Install arrow
git clone https://github.com/apache/arrow -b apache-arrow-${ARROW_VERSION}
cd arrow/
git submodule update --init --recursive

mkdir pyarrow_prefix
export ARROW_HOME=$(pwd)/pyarrow_prefix
export LD_LIBRARY_PATH=$ARROW_HOME/lib64:/usr/local/lib:$LD_LIBRARY_PATH
export CPATH=$ARROW_HOME/include:/usr/local/include:$CPATH
export PKG_CONFIG_PATH=$ARROW_HOME/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

cd  cpp
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -Dutf8proc_LIB=/usr/local/lib/libutf8proc.so \
      -Dutf8proc_INCLUDE_DIR=/usr/local/include \
      -DARROW_PYTHON=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_PARQUET=ON \
      ..
make -j$(nproc)
make install
cd ../../python/
pip install Cython==3.0.8 numpy wheel
CMAKE_PREFIX_PATH=$ARROW_HOME python3 setup.py build_ext --inplace
CMAKE_PREFIX_PATH=$ARROW_HOME python3 setup.py install
cd $CURRENT_DIR

export PYTHON_BIN_PATH=$(which python3)
export PYTHON3_BIN_PATH=$(which python3)
ln -s $PYTHON_BIN_PATH /usr/bin/python

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/ray/ray_ray-2.47.1_1.patch
git apply ray_ray-2.47.1_1.patch

sed -i '/^build --compilation_mode=opt$/a\\n\nbuild:linux --action_env PYTHON_BIN_PATH="'"$(which python3)"'"\n' .bazelrc

cd python/
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export RAY_INSTALL_CPP=1
export BAZEL_ARGS="--define=USE_OPENSSL=1"
export RAY_INSTALL_JAVA=1
pip install --upgrade setproctitle
#Installing ray-cpp
pip install . 

unset RAY_INSTALL_CPP
#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd $CURRENT_DIR/ray
#Test package
# Run all small and medium tests, skipping the following:
# - Tests that failed to build or failed to run due to environment issues (timeouts, crashes)
# - Tests that are too large and do not execute properly in this environment
# - Skipping cgroup_v2_setup_test because it requires write access to /sys/fs/cgroup, which is restricted in sandboxed or containerized environments.
if ! bazel test $(bazel query 'kind(cc_test, ...) except //src/ray/common/cgroup/test:cgroup_v2_setup_test except //src/ray/common/test:resource_set_test except //src/ray/common/test:resource_instance_set_test except //src/ray/util/tests:filesystem_monitor_test except //src/ray/util/tests:signal_test except //src/ray/raylet/scheduling:cluster_resource_manager_test except //src/ray/raylet/scheduling:scheduling_policy_test except //cpp:cluster_mode_test except //cpp:cluster_mode_xlang_test except //cpp:simple_kv_store except //cpp:metric_example except //src/ray/common/cgroup/test:cgroup_v2_utils_privileged_test except //src/ray/gcs/gcs_client/test:global_state_accessor_test') --test_size_filters=small,medium --cxxopt='-Wno-error=maybe-uninitialized' --define=USE_OPENSSL=1 ; then
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


 
