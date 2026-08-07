#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.9.0.post1
# Source repo       : https://github.com/faiss-wheels/faiss-wheels
# Tested on         : UBI 9.6
# Language          : C++, Python
# Ci-Check          : True
# Script License    : Apache License Version 2.0
# Maintainer        : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#

set -e

PACKAGE_NAME=faiss-cpu
PACKAGE_DIR=faiss-wheels
PACKAGE_VERSION=${1:-1.9.0.post1}
PACKAGE_URL=https://github.com/faiss-wheels/faiss-wheels.git
SOURCE_ROOT="$(pwd)"


echo "Installing dependencies..."

dnf install -y  \
     python3-pip \
     openblas-devel make gcc g++ cmake git automake autoconf

echo "Upgrading Python tools..."

python3 -m pip install --upgrade setuptools wheel build uv

git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}

# Append [tool.uv] only if it doesn't already exist to avoid duplicate TOML sections
grep -q '^\[tool\.uv\]' pyproject.toml || \
    echo -e "\n[tool.uv]\nenvironments = [\"python_version == '3.13'\"]" >> pyproject.toml

sed -i "s/version=.*/version='"$PACKAGE_VERSION"',/" third-party/faiss/faiss/python/setup.py
export INDEX_URL_DEVPI="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"
# Make all uv operations (including isolated build envs) use devpi for pre-built wheels
export UV_EXTRA_INDEX_URL="$INDEX_URL_DEVPI"
sed -i '/^\[project\]/,/^$/ {s/version = "[^"]*"/version = "'"$PACKAGE_VERSION"'"/}' pyproject.toml

#find test case called app.py
TEST_PATH=$(find "${SOURCE_ROOT}" -name app.py | head -1)
if [ -z "${TEST_PATH}" ]; then
    echo "ERROR: test case not found"
    exit 1
fi

uv python install 3.13
uv python pin 3.13
CP=$(uv run python -c "import sysconfig; print(sysconfig.get_config_var('py_version_nodot'))")
uv build --wheel --config-setting wheel.py-api=cp$CP --extra-index-url $INDEX_URL_DEVPI

if ! uv pip install --python 3.13 dist/faiss_cpu-$PACKAGE_VERSION-cp$CP-abi3-linux_ppc64le.whl; then
    echo "------------------$PACKAGE_NAME:Failed to install wheel-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
# regex has no cp313 wheel on devpi; query the PEP 691 JSON index directly with curl,
# extract the cp314/ppc64le wheel URL, download it, retag cp314->cp313, force-install
mkdir -p /tmp/regex_whl
REGEX_WHL_URL=$(curl -s -H "Accept: application/vnd.pypi.simple.v1+json" \
    "${INDEX_URL_DEVPI}/regex/" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
urls = [f['url'] for f in data['files']
        if 'cp314' in f['filename'] and 'ppc64le' in f['filename']]
print(urls[0] if urls else '')
")
if [ -z "$REGEX_WHL_URL" ]; then
    echo "ERROR: could not find regex cp314/ppc64le wheel on devpi"
    exit 1
fi
REGEX_WHL_ORIG="/tmp/regex_whl/$(basename $REGEX_WHL_URL)"
curl -sL "$REGEX_WHL_URL" -o "$REGEX_WHL_ORIG"
# rename cp314 tag to cp313 so the installer accepts it on this interpreter
REGEX_WHL_FIXED="${REGEX_WHL_ORIG/cp314-cp314/cp313-cp313}"
mv "$REGEX_WHL_ORIG" "$REGEX_WHL_FIXED"
uv pip install --python 3.13 "$REGEX_WHL_FIXED" --no-deps
uv pip install --python 3.13 scipy==1.17.0 sentence-transformers --extra-index-url $INDEX_URL_DEVPI

if ! uv run python $TEST_PATH; then
     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails--------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
     exit 2
else
     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
     exit 0
fi
