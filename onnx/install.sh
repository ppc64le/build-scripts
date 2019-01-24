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

pip install wheel

git submodule update --init --recursive

bash -c 'export CMAKE_ARGS="-DONNX_WERROR=ON"; \
export CMAKE_ARGS="${CMAKE_ARGS} -DONNXIFI_DUMMY_BACKEND=ON"; \
export ONNX_NAMESPACE=ONNX_NAMESPACE_FOO_BAR_FOR_CI; \
export ONNX_BUILD_TESTS=1; \
python setup.py --quiet bdist_wheel --universal --dist-dir .; \
find . -maxdepth 1 -name "*.whl" -ls -exec pip install {} \;'

mv *.whl "${SCRIPT_DIR}"
cd "${SCRIPT_DIR}"
