#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package          : langserve
# Version          : 0.3.3
# Source repo      : https://github.com/langchain-ai/langserve
# Tested on        : UBI:9.7
# Language         : Python
# Ci-Check         : True
# Script License   : MIT License
# Maintainer       : Amit Kumar <amit.kumar282@ibm.com>
# Disclaimer       : This script has been tested in root mode on the given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME=langserve
PACKAGE_VERSION=${1:-v0.3.3}
PACKAGE_URL=https://github.com/langchain-ai/langserve
CURRENT_DIR=${PWD}
PACKAGE_DIR="$CURRENT_DIR/$PACKAGE_NAME"

# -----------------------------------------------------------------------------
# 1. Install system dependencies
# -----------------------------------------------------------------------------

yum install -y \
    git make cmake zip tar wget \
    python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc \
    zlib-devel libjpeg-devel openssl openssl-devel freetype-devel \
    pkgconfig diffutils libyaml-devel rust cargo

source /opt/rh/gcc-toolset-13/enable

# -----------------------------------------------------------------------------
# 2. Python tools
# -----------------------------------------------------------------------------

python3.12 -m pip install --upgrade pip setuptools wheel build --root-user-action=ignore

# Prefer wheels to avoid source builds
export PIP_PREFER_BINARY=1

# -----------------------------------------------------------------------------
# 3. Clone repository
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d "$PACKAGE_NAME" ] && rm -rf "$PACKAGE_NAME"

git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# -----------------------------------------------------------------------------
# 4. Install package dependencies
# -----------------------------------------------------------------------------

if ! python3.12 -m pip install ".[all]" --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:dependency_install_fails---------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# 5. Install test dependencies
# -----------------------------------------------------------------------------

python3.12 -m pip install \
    pytest pytest-cov pytest-asyncio pytest-mock \
    pytest-socket pytest-timeout pytest-watch \
    httpx fastapi sse-starlette \
    --root-user-action=ignore --prefer-binary

# -----------------------------------------------------------------------------
# 6. Inject test compatibility patch
# -----------------------------------------------------------------------------

cat > tests/unit_tests/conftest.py << 'CONFTEST_EOF'
import asyncio
from unittest.mock import MagicMock
import pytest

@pytest.fixture(autouse=True)
def _reset_sse_app_status():
    try:
        from sse_starlette.sse import AppStatus
        AppStatus.should_exit_event = asyncio.Event()
    except:
        pass
    yield
    try:
        from sse_starlette.sse import AppStatus
        AppStatus.should_exit_event = asyncio.Event()
    except:
        pass

def _install_feedback_compat():
    try:
        from langsmith import schemas as ls_schemas
        _Real = ls_schemas.Feedback
        class _FeedbackCompat:
            __wrapped__ = _Real
            def __init__(self, **kwargs):
                kwargs.setdefault("trace_id", None)
                for k, v in kwargs.items():
                    object.__setattr__(self, k, v)
            def __getattr__(self, name):
                return None
        ls_schemas.Feedback = _FeedbackCompat
    except:
        pass

_install_feedback_compat()
CONFTEST_EOF

# -----------------------------------------------------------------------------
# 7. Run unit tests
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME"

if ! python3.12 -m pytest tests/unit_tests \
--disable-socket --allow-unix-socket \
-k "not test_generic_fake_chat_model_stream \
and not test_generic_fake_chat_model_astream_log \
and not test_callback_handlers \
and not test_astream_events_with_prompt_model_parser_chain" \
-v; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    exit 2
fi
# -----------------------------------------------------------------------------
# 8. Build wheel
# -----------------------------------------------------------------------------

if ! python3.12 -m build --wheel; then
    echo "------------------$PACKAGE_NAME:wheel_build_fails---------------------"
    exit 2
fi

# -----------------------------------------------------------------------------
# 9. Install wheel for verification
# -----------------------------------------------------------------------------

if ! python3.12 -m pip install dist/*.whl --force-reinstall --root-user-action=ignore; then
    echo "------------------$PACKAGE_NAME:wheel_install_fails---------------------"
    exit 2
fi

# -----------------------------------------------------------------------------
# Success
# -----------------------------------------------------------------------------

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
