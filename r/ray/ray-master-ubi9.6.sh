#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : ray
# Version       : master(0e484d33586d18cc0b205)
# Source repo   : https://github.com/ray-project/ray
# Tested on     : UBI 9.6
# Language      : C++, Python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ray
PYSPY_VERSION=v0.3.14
ARROW_VERSION=16.1.0
BAZEL_VERSION=6.5.0
wdir=`pwd`

yum install -y git gcc g++ patch pkg-config zip unzip gfortran wget java-11-devel python3-devel python3-pip openssl-devel cmake perl libxcrypt-compat procps

yum config-manager  --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os && \
yum config-manager  --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
yum config-manager  --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official 

ln -s /usr/bin/python3 /usr/bin/python  

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > sh.rustup.rs && \
sh ./sh.rustup.rs -y && export PATH=$PATH:$HOME/.cargo/bin && . "$HOME/.cargo/env"
 
# Install py-spy
cd $wdir
git clone https://github.com/benfred/py-spy -b ${PYSPY_VERSION}
cd py-spy && cargo install py-spy
pip install --upgrade maturin
maturin build --release -o dist
pip install dist/py_spy*_ppc64le.whl

#Install arrow
yum install -y boost-devel utf8proc-devel
cd $wdir
git clone https://github.com/apache/arrow -b apache-arrow-${ARROW_VERSION}
cd arrow/
git submodule update --init --recursive
cd  cpp
mkdir build
cd build
export ARROW_HOME=/repos/dist
export LD_LIBRARY_PATH=/repos/dist/lib64:$LD_LIBRARY_PATH
cmake -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=$ARROW_HOME -Dutf8proc_LIB=/usr/lib64/libutf8proc.so -Dutf8proc_INCLUDE_DIR=/usr/include -DARROW_PYTHON=on -DARROW_BUILD_TESTS=ON -DARROW_PARQUET=ON ..
make -j$(nproc)
make install
cd ../../python/
pip install Cython==3.0.8 numpy wheel
CMAKE_PREFIX_PATH=/repos/dist python setup.py build_ext --inplace
CMAKE_PREFIX_PATH=/repos/dist python setup.py install

#Install bazel
cd $wdir
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.25.0.9-7.el9.ppc64le
export PATH=$JAVA_HOME/bin:$PATH
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH

#Install Ray
cd $wdir
git clone https://github.com/ray-project/ray
cd ray/

git apply $wdir/upstream_pr_51673.patch
git apply $wdir/ray-master-openssl.patch
git apply $wdir/ray-rules-perl.patch

cd python/
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export RAY_INSTALL_CPP=1
export BAZEL_ARGS="--define=USE_OPENSSL=1 --jobs=10"
export RAY_INSTALL_JAVA=1
python3 setup.py build
python3 setup.py bdist_wheel
unset RAY_INSTALL_CPP
python3 setup.py build
python3 setup.py bdist_wheel

#Install wheel
cd $wdir/${PACKAGE_NAME}/python/dist
pip install ray_cpp*-linux_ppc64le.whl
pip install ray-*-linux_ppc64le.whl

#Test (CPP)
#cd $wdir/${PACKAGE_NAME}
#bazel test --jobs=10 $(bazel query 'kind(cc_test, ...)') --cxxopt='-Wno-error=maybe-uninitialized' --define=USE_OPENSSL=1|| true

#These test cases pass successfully when run separately.
#bazel test --jobs=10 //cpp:simple_kv_store --cxxopt='-Wno-error=maybe-uninitialized' --define=USE_OPENSSL=1|| true
#bazel test --jobs=10 //cpp:cluster_mode_xlang_test --cxxopt='-Wno-error=maybe-uninitialized' --define=USE_OPENSSL=1|| true
#bazel test --jobs=10 //cpp:metric_example  --cxxopt='-Wno-error=maybe-uninitialized' --define=USE_OPENSSL=1|| true
