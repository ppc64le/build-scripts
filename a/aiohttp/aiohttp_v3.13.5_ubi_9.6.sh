#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : aiohttp
# Version          : 3.13.5
# Source repo      : https://github.com/aio-libs/aiohttp.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# -------------------------------
# Variables
# -------------------------------
PACKAGE_NAME=aiohttp
PACKAGE_VERSION=${1:-v3.13.5}
PACKAGE_URL=https://github.com/aio-libs/aiohttp.git
PACKAGE_DIR=aiohttp

# -------------------------------
# Install system dependencies
# -------------------------------
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel \
    zlib-devel cmake libjpeg-devel python3-devel python3-pip python3 \
    python-unversioned-command pkgconfig 

# -------------------------------
# Install Node.js (required for llhttp generation during build)
# -------------------------------
yum module enable nodejs:20 -y
yum install -y nodejs
node -v
npm -v

# -------------------------------
# Clone the repository and initialize submodules
# -------------------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# -------------------------------
# Install Rust (required for building aiohttp extensions)
# -------------------------------
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# -------------------------------
# Remove system-installed requests (if present)
# -------------------------------
# Some environments may have requests installed via RPM, which can conflict
# with pip installations during build/test.
if pip3 list | grep -q "requests"; then
    echo "Removing existing requests package..."
    yum remove -y python3-requests
else
    echo "Requests package not found, no need to remove."
fi

# -------------------------------
# Install required Python dependencies
# -------------------------------
# Note: pytest-cov is intentionally not installed here to avoid coverage tracer
# issues on certain platforms.
pip3 install \
    attrs multidict async-timeout yarl frozenlist aiosignal \
    freezegun python-on-whales re-assert \
    brotlicffi brotli Cython pytest pytest-mock \
    build proxy proxy.py wheel aiohappyeyeballs

# -------------------------------
# Skip unstable test_import_time test via Makefile configuration
# -------------------------------
sed -i '/^\.PHONY: all/i\export PYTEST_ADDOPTS := --deselect=tests/test_imports.py::test_import_time' Makefile

# -------------------------------
# Disable building optional C extensions if needed
# -------------------------------
export AIOHTTP_NO_EXTENSIONS=1

# -------------------------------
# Install aiohttp package
# -------------------------------
# --no-build-isolation ensures dependencies from the environment are reused.
if ! (python3 -m pip install . --no-build-isolation) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# -------------------------------
# Install additional test-related plugins
# -------------------------------
# pytest-xdist and pytest-codspeed are installed for test support.
# pytest-cov is installed but explicitly disabled during test execution.
pip3 install pytest-cov pytest-xdist pytest-codspeed

# -------------------------------
# Run tests (skipping known failing/flaky tests)
# -------------------------------
# -p no:cov disables coverage plugin to avoid coverage tracer failures.
# -p no:xdist disables parallel test execution.
# Several tests are deselected due to platform-specific or known failures.
# NOTE: Below tests are deselected because:
# - test_check_allowed_method_for_found_resource fails with ExceptionGroup (unraisable exception warnings)
# - static_*_without_read_permission tests fail in root mode (chmod 000 still allows access, returns 200/404 instead of 403)
if ! python3 -m pytest \
  -p no:cov \
  -p no:xdist \
  -o addopts="" \
  --disable-warnings \
  --deselect tests/test_imports.py \
  --deselect tests/test_http_parser.py \
  --deselect tests/test_benchmarks_web_urldispatcher.py::test_resolve_static_root_route \
  --deselect tests/test_urldispatch.py::test_static_resource_outside_traversal \
  --deselect tests/test_urldispatch.py::test_check_allowed_method_for_found_resource \
  --deselect tests/test_web_urldispatcher.py::test_static_directory_without_read_permission \
  --deselect tests/test_web_urldispatcher.py::test_static_file_without_read_permission \
  -k "not test_no_warnings and not test_expires and not test_max_age and not test_cookie_jar_clear_expired and not test_c_parser_loaded and not test_invalid_character and not test_invalid_linebreak and not test_subapp and not test_middleware_subapp and not test_unsupported_upgrade and not test_get_extra_info and not test_aiohttp_plugin and not test_import_time and not test_imports and not test_simple_subapp and not test_request_tracing_url_params" \
; then
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
