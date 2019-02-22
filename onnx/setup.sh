# ----------------------------------------------------------------------------
#
# Package	: ONNX
# Version	: 1.4
# Source repo	: https://github.com/onnx/onnx.git
# Tested on	: ubuntu 18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Chin Huang <chhuang@us.ibm.com>
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

export NUMCORES=`grep -c ^processor /proc/cpuinfo`
if [ ! -n "$NUMCORES" ]; then
  export NUMCORES=`sysctl -n hw.ncpu`
fi
echo Using $NUMCORES cores

sudo apt-get update 

sudo apt-get install -y \
         protobuf-compiler \
         libprotobuf-dev \
         cmake 

# Use python3 or python2 venv based on env variable PYTHON_VERSION
if [ "${PYTHON_VERSION}" = "python3" ]; then
    sudo apt-get install -y \
         python3-pip \
         python3-venv
    python3 -m venv venv_py3
    . ./venv_py3/bin/activate
else
    sudo apt-get install -y \
         python-pip
    sudo -H pip install virtualenv
    virtualenv venv_py2
    . ./venv_py2/bin/activate
fi

python -V
pip -V

# Need to delete onnx folder if existing
if [ -d "onnx" ]; then
  rm -rf onnx
fi

sudo apt install -y git
git clone https://github.com/onnx/onnx.git
