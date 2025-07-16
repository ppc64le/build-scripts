#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : oci-cli
# Version       : 3.29.1 
# Source repo   : https://github.com/oracle/oci-cli
# Tested on     : UBI:9.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Environment Variables 
OCI_CLI_VERSION=${1:-"v3.29.1"}
BUILD_HOME="$(pwd)"
PYYAML_DIR="pyyaml"
PYYAML_VERSION=${1:-"6.0"}
PYYAML_REPO="https://github.com/yaml/pyyaml.git"

#Install required dependencies
yum install -y git gcc gcc-c++ openssl-devel python3.12 python3.12-devel python3.12-pip libyaml-devel 

# Optional: activate a virtualenv if desired
# python3.12 -m venv <venv_name> && source <venv_name>/bin/activate

#Install PyYAML-6.0 from source (Required PyYAML<=6,>=5.4 in oci-cli:3.29.1)
python3.12 -m pip install --upgrade pip
python3.12 -m pip install "cython<3.0.0" wheel setuptools
PATH=$PATH:/usr/local/bin/

#Clone the PyYaml repository 
cd "$BUILD_HOME"
git clone "$PYYAML_REPO"
cd "$PYYAML_DIR"
git checkout $PYYAML_VERSION

# Build PyYaml
ret=0
python3.12 setup.py install || ret=$?
if [ "$ret" -ne 0 ]
then
    exit 1
fi

cd "$BUILD_HOME"
#Install rust (required for cryptography)
curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
rustc --version

# Install oci-cli 
python3.12 -m pip install oci-cli==$OCI_CLI_VERSION || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "oci-cli installation failed."
    exit 2
fi

#oci --version
 
# Validate Installation
python3.12 -c "import oci_cli; print(oci_cli.__version__)" || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "Smoke test failed: Could not import oci_cli."
    exit 2
else
    echo "oci-cli $OCI_CLI_VERSION installed and verified successfully."
fi

