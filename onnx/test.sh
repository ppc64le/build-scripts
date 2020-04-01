# ----------------------------------------------------------------------------
#
# Package       : ONNX
# Version       : 1.4
# Source repo   : https://github.com/onnx/onnx.git
# Tested on     : ubuntu 18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Chin Huang <chhuang@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             A non-root user must be created with sudo permissions.
#             The default python version is python 2.7. To build and
#             test in python3, the environment varible PYTHON_VERSION
#             must be set to "python3".
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

if [ "${PYTHON_VERSION}" = "python3" ]; then
    . ./venv_py3/bin/activate
else
    . ./venv_py2/bin/activate
fi

export SCRIPT_DIR="${PWD}"
cd onnx

pip install pyzmq==17.1.2
pip install -q numpy pytest nbval flake8

# onnx c++ API tests
export LD_LIBRARY_PATH="./.setuptools-cmake-build/:$LD_LIBRARY_PATH"
./.setuptools-cmake-build/onnx_gtests
./.setuptools-cmake-build/onnxifi_test_driver_gtests onnx/backend/test/data/node

# onnx python API tests
pytest

# lint python code
flake8

pip uninstall -y onnx
bash -c 'rm -rf .setuptools-cmake-build; \
pip install .'

# check line endings to be UNIX
sudo apt install dos2unix -y
find . -type f -regextype posix-extended -regex '.*\.(py|cpp|md|h|cc|proto|proto3|in)' | xargs dos2unix --quiet
git status
git diff --exit-code

# check auto-gen files up-to-date
python onnx/defs/gen_doc.py
python onnx/gen_proto.py -l
python onnx/gen_proto.py -l --ml
python onnx/backend/test/stat_coverage.py
backend-test-tools generate-data
git status
git diff --exit-code

# Do not hardcode onnx's namespace in the c++ source code, so that
# other libraries who statically link with onnx can hide onnx symbols
# in a private namespace.
! grep -R '--include=*.cc' '--include=*.h' 'namespace onnx' .
! grep -R '--include=*.cc' '--include=*.h' onnx:: .

cd "${SCRIPT_DIR}"
