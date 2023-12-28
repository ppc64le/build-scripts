#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rules_python
# Version          : 0.27.1
# Source repo      : https://github.com/bazelbuild/rules_python
# Tested on        : UBI 8.7
# Language         : Starlark,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="rules_python"
PACKAGE_VERSION=${1:-"0.27.1"}
PACKAGE_URL=https://github.com/bazelbuild/rules_python

# Install dependencies
yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc zip diffutils protobuf-c patch gcc-gfortran openssl-devel openssl python3.11-pip python3.11 python3.11-devel sudo

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.4.0/bazel-6.4.0-dist.zip
mkdir -p  bazel-6.4.0
unzip bazel-6.4.0-dist.zip -d bazel-6.4.0/
cd bazel-6.4.0/
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash
./compile.sh
#export the path of bazel bin
export PATH=$PATH:`pwd`/output
cd ../

#Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

  # Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
wget https://raw.githubusercontent.com/vinodk99/build-scripts/rules_python1/r/rules_python/rules_python_0.27.1.patch
patch -p1 < rules_python_0.27.1.patch

# Install
if ! bazel build //... ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run the test cases
if ! bazel test --flaky_test_attempts=3 --build_tests_only --local_test_jobs=12 --show_progress_rate_limit=5 --curses=yes --color=yes --terminal_columns=143 --show_timestamps --verbose_failures --jobs=30 --announce_rc --experimental_repository_cache_hardlinks --disk_cache= --sandbox_tmpfs_path=/tmp --experimental_build_event_json_file_path_conversion=false  --remote_max_connections=200 --test_tag_filters=-integration-test --test_env=HOME --test_env=BAZELISK_USER_AGENT ... ; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
