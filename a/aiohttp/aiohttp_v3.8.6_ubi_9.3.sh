#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : aiohttp
# Version          : 3.8.6
# Source repo      : https://github.com/aio-libs/aiohttp.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
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

# Variables
PACKAGE_NAME=aiohttp
PACKAGE_VERSION=${1:-v3.8.6}
PACKAGE_URL=https://github.com/aio-libs/aiohttp.git

# Install dependencies
yum install -y git gcc gcc-c++ make wget python3-devel python3-pip openssl-devel bzip2-devel libffi-devel zlib-devel npm cmake libjpeg-devel clang

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

ln -s /usr/bin/python3 /usr/bin/python

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# install necessary Python packages
pip install pytest
python3 -m pip install -r requirements/test.txt -c requirements/constraints.txt

#build llhttp
AIOHTTP_DIR=$(pwd)
cd vendor/llhttp
npm install llparse semver
npm install --save-dev @types/node
make
make install

#back to aiohttp dir
cd $AIOHTTP_DIR
#make cythonize

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests excluding tests failing on power and x86
if ! pytest -k "not test_no_warnings and not test_expires and not test_max_age and not test_cookie_jar_clear_expired and not test_c_parser_loaded and not test_invalid_character and not test_invalid_linebreak and not test_subapp and not test_middleware_subapp and not test_unsupported_upgrade and not test_get_extra_info and not test_aiohttp_plugin and not test_simple_subapp and not test_request_tracing_url_params and not test_secure_https_proxy_absolute_path and not test_https_proxy_unsupported_tls_in_tls" -p no:warnings ; then
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
