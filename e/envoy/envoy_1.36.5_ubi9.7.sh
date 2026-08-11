#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy
# Version       : v1.36.5
# Source repo   : https://github.com/envoyproxy/envoy/
# Tested on     : UBI 9.7
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
 
PACKAGE_NAME=envoy
PACKAGE_ORG=envoyproxy
SCRIPT_PACKAGE_VERSION=v1.36.5
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
SCRIPT_PACKAGE_VERSION_WO_LEADING_V="${SCRIPT_PACKAGE_VERSION:1}"
scriptdir=$(dirname $(realpath $0))
wdir=$(pwd)


# =============================================================================
# STAGE 1 — Base dependencies
# =============================================================================
#Install centos and epel repos
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
 
yum install -y \
    cmake \
    libatomic \
    libstdc++ \
    libstdc++-static \
	libstdc++-devel \
    libtool \
    lld \
    patch \
    python3.12-pip \
    openssl-devel \
    libffi-devel \
    unzip \
    wget \
    zip \
    java-21-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    procps \
    diffutils \
    ninja-build \
    aspell \
    aspell-en \
    sudo \
	python3.12 \
    python3.12-devel \
    python3.12-pip \
    glibc-devel \
    glibc-headers


#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
export ENVOY_BIN=$wdir/envoy/envoy-static
export ENVOY_ZIP=$wdir/envoy/envoy-static_${PACKAGE_VERSION}_UBI9.6.zip

#Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply --check --ignore-space-change --whitespace=fix $scriptdir/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION_WO_LEADING_V}.patch
git apply --ignore-space-change --whitespace=fix $scriptdir/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION_WO_LEADING_V}.patch
BAZEL_VERSION=$(cat .bazelversion)

#Build and setup bazel
cd $wdir
if [ -z "$(ls -A $wdir/bazel)" ]; then
	mkdir bazel
	cd bazel
	wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
	unzip bazel-${BAZEL_VERSION}-dist.zip
	rm -rf bazel-${BAZEL_VERSION}-dist.zip
	export BAZEL_DEV_VERSION_OVERRIDE=${BAZEL_VERSION}
	env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
	#EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk" ./compile.sh
fi
export PATH=$PATH:$wdir/bazel/output


#Setup clang
cd $wdir
if [ -z "$(ls -A $wdir/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8)" ]; then
	wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz
	tar -xvf clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz
	rm -rf clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz
fi

#Install rust and cross
curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
cargo install cross --version 0.2.1

 
#Build cargo-bazel native binary
cd $wdir
if [ -z "$(ls -A $wdir/rules_rust)" ]; then
	git clone https://github.com/bazelbuild/rules_rust
	cd rules_rust
	git checkout 0.56.0
	cd crate_universe
	cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu
	echo "cargo-bazel build successful!"
fi
export CARGO_BAZEL_GENERATOR_URL=file://$wdir/rules_rust/crate_universe/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel
export CARGO_BAZEL_REPIN=true

export LLVM_DIR=$wdir/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8
export PATH=$LLVM_DIR/bin:$PATH
export CC=$LLVM_DIR/bin/clang
export CXX=$LLVM_DIR/bin/clang++
export LLVM_CONFIG=$LLVM_DIR/bin/llvm-config
export LIBCLANG_PATH=$LLVM_DIR/lib

#extra
export LLVM_CONFIG=$LLVM_DIR/bin/llvm-config
export LIBCLANG_PATH=$LLVM_DIR/lib
export LD_LIBRARY_PATH=$LLVM_DIR/lib:/usr/lib64
export BINDGEN_EXTRA_CLANG_ARGS="-isystem $LLVM_DIR/lib/clang/18/include -isystem /usr/include --sysroot=/"
export BAZEL_LINKOPTS="-fuse-ld=lld"
export RUST_BACKTRACE=1
export AR=$LLVM_DIR/bin/llvm-ar
export NM=$LLVM_DIR/bin/llvm-nm
export RANLIB=$LLVM_DIR/bin/llvm-ranlib

#Build Envoy
cd $wdir/${PACKAGE_NAME}
bazel/setup_clang.sh $wdir/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8/
ret=0
bazel build //source/exe:envoy  -c opt  --config=clang-gnu   --define=wasm=disabled --jobs=8 --local_resources=memory=24000 || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi


#Prepare binary for distribution
cp $wdir/envoy/bazel-bin/source/exe/envoy-static $ENVOY_BIN
chmod -R 755 $wdir/envoy
strip -s $ENVOY_BIN
zip $ENVOY_ZIP envoy-static

# Smoke test
$ENVOY_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Smoke test failed."
	exit 2
fi


# Commenting out test commands in this PR as they take more than 6 hours to complete, which exceeds the CI time limit.
# Please uncomment and run the tests locally if needed.
# The reasons for skipping the 7 tests are documented in the README file.

# ============================================================================
# STAGE 2 — Envoy tests
# ============================================================================

#if command -v python3.12 >/dev/null 2>&1; then
#  PY312_BIN=$(command -v python3.12)
#elif [ -x /usr/local/bin/python3.12 ]; then
#  PY312_BIN=/usr/local/bin/python3.12
#elif [ -x /usr/bin/python3.12 ]; then
#  PY312_BIN=/usr/bin/python3.12
#else
#  echo "ERROR: python3.12 not found in PATH or common locations"
#  exit 1
#fi

#export PY312_BIN
#export PYTHON_BIN_PATH="$PY312_BIN"
#export PYTHONPATH="$("$PY312_BIN" -c 'import site; print(":".join(site.getsitepackages()))')"


#"$PY312_BIN" -m pip install cryptography
#"$PY312_BIN" -m pip install jinja2
#"$PY312_BIN" -m pip install absl-py
#"$PY312_BIN" -m pip install thrift

#bazel test \
#  //test/... \
#  --config=clang-gnu \
#  --define=wasm=disabled \
#  --override_repository=base_pip3=third_party/python_stub \
#  --override_repository=v8_python_deps=third_party/v8_python_deps \
#  --override_repository=fuzzing_pip3=third_party/python_stub_fuzzing \
#  --action_env=PYTHON_BIN_PATH="$PY312_BIN" \
#  --action_env=BINDGEN_EXTRA_CLANG_ARGS="$BINDGEN_EXTRA_CLANG_ARGS" \
#  --action_env=PYTHONPATH="$PYTHONPATH" \
#  --action_env=BAZEL_LINKOPTS= 
#  --test_output=errors \
#  --cache_test_results=no \
#  -jobs=8 \
#  --local_ram_resources=12000 
#  -- \
#  -//test/common/network:io_socket_handle_impl_integration_test \
#  -//test/common/tls:tls_throughput_benchmark_test \
#  -//test/config_test:example_configs_test \
#  -//test/integration:tcp_proxy_integration_test \
#  -//test/integration:stats_integration_test \
#  -//test/extensions/dynamic_modules:rust_sdk_doc_test \
#  -//test/extensions/dynamic_modules/http:filter_test \
#  -//test/extensions/dynamic_modules/http:integration_test
