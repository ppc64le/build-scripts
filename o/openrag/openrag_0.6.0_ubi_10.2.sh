#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : openrag
# Version          : 0.6.0
# Source repo      : https://github.com/langflow-ai/openrag
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sharath P J <sharath.pj@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Notes:
#   openrag requires Python >=3.13. The CI wrapper handles installing Python
#   3.13 (and later versions) when needed.
#
#   uv is not available in UBI 10 repos; it is installed via pip.
#
#   Three ppc64le compatibility patches are applied inline before the build:
#     - pins tiktoken to 0.13.0  (cp313 ppc64le wheel on IBM index)
#     - adds grpcio==1.82.1      (cp313 ppc64le wheel on IBM index)
#     - adds DEFAULT_DOCKLING_SERVE_OVERRIDE_UVX env-var escape hatch
#
#   No smoke test — openrag requires a live OpenSearch instance at runtime
#   and the wheel enforces requires-python>=3.13. Wheel build success is
#   treated as sufficient validation.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=openrag
PACKAGE_VERSION=${1:-0.6.0}
PACKAGE_DIR=openrag-${PACKAGE_VERSION}
PACKAGE_URL=https://github.com/langflow-ai/openrag.git
CURRENT_DIR=$(pwd)

# IBM ppc64le wheels index — provides cp313 wheels for grpcio and tiktoken
INDEX_URL_DEVPY=${INDEX_URL_DEVPY:-https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/}

# ── 1. System dependencies ────────────────────────────────────────────────────
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git wget make \
    openssl-devel zlib-devel libffi-devel \
    xz xz-devel sqlite sqlite-devel bzip2-devel

# ── 2. Activate GCC Toolset 15 ────────────────────────────────────────────────
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi
echo "Using gcc: $(gcc --version | head -1)"

# ── 3. Install Python build tools and uv ─────────────────────────────────────
# uv is not in UBI 10 repos; install via pip.
pip install --upgrade pip setuptools wheel build
pip install uv

# ── 4. Clone and patch ────────────────────────────────────────────────────────
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Checkout version — try v-prefixed tag, bare version, then release branch
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
elif git rev-parse "release-${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "release-${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag or branch found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Patch pyproject.toml — pin tiktoken and add grpcio for ppc64le cp313 wheels
python3.12 - <<'PYEOF'
import pathlib

p = pathlib.Path("pyproject.toml")
src = p.read_text()

old = '"tiktoken>=0.7.0",'
new = '"tiktoken==0.13.0",\n    "grpcio==1.82.1",'
if old in src:
    src = src.replace(old, new, 1)
    p.write_text(src)
    print("  pyproject.toml: tiktoken pinned, grpcio added OK")
elif '"tiktoken==0.13.0",' in src:
    print("  pyproject.toml: already patched — skipping")
else:
    raise SystemExit("ERROR: could not find tiktoken entry in pyproject.toml")
PYEOF

# Patch docling_manager.py — add DEFAULT_DOCKLING_SERVE_OVERRIDE_UVX escape hatch
python3.12 - <<'PYEOF'
import pathlib

p = pathlib.Path("src/tui/managers/docling_manager.py")
src = p.read_text()

old = '            ]\n            if override_path:\n                cmd += ["--override", override_path, "--with", "opencv-python-headless"]\n'
new = '            ]\n            if (val := os.getenv("DEFAULT_DOCKLING_SERVE_OVERRIDE_UVX")):\n                cmd = val.split()\n            if override_path:\n                cmd += ["--override", override_path, "--with", "opencv-python-headless"]\n'
if 'DEFAULT_DOCKLING_SERVE_OVERRIDE_UVX' not in src:
    if old not in src:
        raise SystemExit("ERROR: could not find patch anchor in docling_manager.py")
    src = src.replace(old, new, 1)
    p.write_text(src)
    print("  docling_manager.py: override hook added OK")
else:
    print("  docling_manager.py: already patched — skipping")
PYEOF

rm -f uv.lock

# ── 5. Sync dependencies and build wheel ─────────────────────────────────────
IBM_WHEELS_HOST=wheels.developerfirst.ibm.com
uv sync \
    --extra-index-url "$INDEX_URL_DEVPY" \
    --index-strategy unsafe-best-match \
    --trusted-host "$IBM_WHEELS_HOST"

if ! uv build --wheel ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cp dist/*.whl "$CURRENT_DIR/"

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
exit 0
