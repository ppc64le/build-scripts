#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ray
# Version          : ray-2.52.1
# Source repo      : https://github.com/ray-project/ray
# Tested on        : UBI:9.6
# Language         : Python, C++
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ray
PACKAGE_VERSION=${1:-ray-2.52.1}
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

export PYTHON_BIN_PATH=$(which python3)
export PYTHON3_BIN_PATH=$(which python3)
ln -s $PYTHON_BIN_PATH /usr/bin/python

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/ray/upstream_pr_51673_2521.patch
git apply upstream_pr_51673_2521.patch

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/ray/ray-master-openssl.patch
git apply ray-master-openssl.patch

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/ray/ray-rules-perl.patch
git apply ray-rules-perl.patch

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/ray/ray-boost.patch
git apply ray-boost.patch

sed -i '/^build --compilation_mode=opt$/a\\n\nbuild:linux --action_env PYTHON_BIN_PATH="'"$(which python3)"'"\n' .bazelrc

# Install NodeJS
dnf install -y nodejs npm

# Build Ray dashboard frontend
cd python/ray/dashboard/client
npm ci
npm run build
cd $CURRENT_DIR/$PACKAGE_NAME

cd python/
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export RAY_INSTALL_CPP=1
export BAZEL_ARGS="--define=USE_OPENSSL=1 --jobs=10 --define=SKIP_RULES_PERL=1 --strategy=CppCompile=standalone"
export RAY_INSTALL_JAVA=1

pip install Cython
#Installing ray-cpp
pip install . 

unset RAY_INSTALL_CPP
#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
fi


echo "Validating Ray with dashboard build..."

if ! python <<'EOF'
import ray
import os

ray_path = os.path.dirname(ray.__file__)
dashboard_build = os.path.join(ray_path, "dashboard", "client", "build")

print("Ray version:", ray.__version__)
print("Ray path:", ray_path)
print("Dashboard build path:", dashboard_build)

assert os.path.isdir(dashboard_build), "Dashboard build directory is missing!"

index_file = os.path.join(dashboard_build, "index.html")
assert os.path.isfile(index_file), "Dashboard index.html is missing!"

print("Dashboard build verified successfully")
EOF
then
    echo "------------------ ray-dashboard: validation_failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Validation_Failed"
    exit 1
fi

echo "Ray with dashboard validation successful"
