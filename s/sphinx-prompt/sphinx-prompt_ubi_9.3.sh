#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sphinx-prompt
# Version          : 1.9.0
# Source repo      : https://github.com/sbrunner/sphinx-prompt.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
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
set -ex

#variables
PACKAGE_NAME=sphinx-prompt
PACKAGE_VERSION=${1:-1.9.0}
PACKAGE_URL=https://github.com/sbrunner/sphinx-prompt.git
PACKAGE_DIR=sphinx-prompt
CURRENT_DIR="${PWD}"

#install dependencies
yum install -y git gcc-toolset-13 wget openssl-devel bzip2-devel libffi-devel zlib-devel ncurses libffi sqlite sqlite-devel sqlite-libs python3.11  python3.11-devel python3.11-pip make cmake

#export gcc-toolset path
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.11 -m pip install -r requirements.txt
python3.11 -m pip install sphinx==8.0.2
python3.11 -m pip install poetry
python3.11 -m pip install --upgrade pytest

#Ensure Poetry explicitly includes the 'sphinx_prompt' package by adding a packages section after [tool.poetry] in pyproject.toml to avoid missing module errors.
sed -i '/^packages = \[/,/\]/d' pyproject.toml
sed -i '/^\[tool.poetry\]/a packages = [\n    { include = "sphinx_prompt" }\n]' pyproject.toml
#install

if ! poetry install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "build and save wheel to current dir, because using default python build command not able to detect version"
poetry build
mv dist/*.whl "$CURRENT_DIR"

#test
if ! poetry run pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
