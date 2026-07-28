#
# Package          : composio
# Version          : py@0.16.0
# Source repo      : https://github.com/composiohq/composio
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_DIR="composio-src"
PACKAGE_NAME="composio"
PACKAGE_VERSION=${1:-py@0.16.0}
PACKAGE_URL="https://github.com/composiohq/composio.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y \
    git \
    python3.12 \
    python3.12-devel \
    python3.12-pip

# Install build frontend
python3.12 -m pip install --upgrade pip
python3.12 -m pip install build setuptools wheel

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"

# The Python SDK lives under the python/ subdirectory of the monorepo
cd python

# Build wheel
# composio is a pure-Python package; no C extensions, no CMake, no Rust.
# Standard pip wheel is sufficient.
python3.12 -m pip wheel . --no-deps -w "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# Copy wheel to /home/tester so the wrapper script can locate it without rebuilding
if [ -d /home/tester ]; then
    cp "${WHEEL}" /home/tester/
fi

cd "${SOURCE_ROOT}"

# Install wheel + test dependencies
echo "=== Installing Wheel ==="
python3.12 -m pip install "${WHEEL}"
python3.12 -m pip install pytest pytest-timeout pytest-mock

# Run tests
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('composio version:', importlib.metadata.version('composio'))"

# 2. Smoke tests — run from a temp directory OUTSIDE the source tree so that
#    Python resolves 'composio' from the installed wheel, not the local source.
#    The upstream test suite requires a live Composio API key for most tests;
#    we therefore write a minimal standalone test that exercises the installed
#    package's public API surface without any network calls.
SMOKE_DIR=$(mktemp -d)
cat > "${SMOKE_DIR}/test_smoke.py" << 'PYEOF'
import importlib.metadata
import pytest


def test_version():
    version = importlib.metadata.version("composio")
    assert version == "0.16.0", f"Unexpected version: {version}"


def test_package_has_version_attr():
    import composio
    assert hasattr(composio, "__version__"), "__version__ not found on composio package"


def test_import_top_level():
    """All public symbols re-exported from the top-level package."""
    from composio import (
        Composio,
        ToolkitLatestVersion,
        ToolkitVersion,
        ToolkitVersionParam,
        ToolkitVersions,
        after_execute,
        before_execute,
        schema_modifier,
    )
    assert Composio is not None
    assert after_execute is not None
    assert before_execute is not None
    assert schema_modifier is not None


def test_import_types():
    from composio.types import (
        Modifiers,
        Tool,
        ToolExecuteParams,
        ToolExecutionResponse,
        ToolkitLatestVersion,
        ToolkitVersion,
        ToolkitVersionParam,
        ToolkitVersions,
        TriggerEvent,
        auth_scheme,
    )
    assert Tool is not None
    assert ToolExecuteParams is not None
    assert ToolExecutionResponse is not None
    assert TriggerEvent is not None
    assert Modifiers is not None
    assert auth_scheme is not None


def test_import_core_types():
    from composio.core.types import (
        ToolkitLatestVersion,
        ToolkitVersion,
        ToolkitVersionParam,
        ToolkitVersions,
    )
    assert ToolkitLatestVersion is not None
    assert ToolkitVersion is not None
    assert ToolkitVersions is not None
    assert ToolkitVersionParam is not None


def test_import_core_models():
    from composio.core.models import (
        AuthConfigs,
        ConnectedAccounts,
        Toolkits,
        Tools,
        Triggers,
    )
    assert AuthConfigs is not None
    assert ConnectedAccounts is not None
    assert Toolkits is not None
    assert Tools is not None
    assert Triggers is not None


def test_import_exceptions():
    from composio import exceptions
    assert hasattr(exceptions, "ApiKeyNotProvidedError")


def test_import_sdk():
    from composio.sdk import Composio
    assert Composio is not None


def test_no_circular_imports():
    """Guard against circular import regressions."""
    from composio import Composio  # noqa: F401
    from composio.core.models.tools import Tools  # noqa: F401
    from composio.core.types import ToolkitVersion  # noqa: F401
    from composio.types import ToolkitVersionParam  # noqa: F401


def test_dereference_json_schema_basic():
    """Smoke-test the JSON Schema $ref inliner."""
    from composio.utils.json_schema import dereference_json_schema

    out = dereference_json_schema(
        {
            "type": "object",
            "properties": {"name": {"$ref": "#/$defs/Name"}},
            "$defs": {"Name": {"type": "string"}},
        }
    )
    assert out["properties"]["name"] == {"type": "string"}
    assert "$defs" not in out


def test_normalize_tool_arguments():
    """Smoke-test the tool-argument normaliser."""
    from composio.utils.shared import normalize_tool_arguments

    assert normalize_tool_arguments({"k": "v"}) == {"k": "v"}
    assert normalize_tool_arguments('{"k": "v"}') == {"k": "v"}
    assert normalize_tool_arguments(None) == {}
PYEOF

python3.12 -m pytest "${SMOKE_DIR}/test_smoke.py" \
    -v \
    --timeout=60 \
    -x

TEST_EXIT=$?
rm -rf "${SMOKE_DIR}"

if [ "$TEST_EXIT" -ne 0 ]; then
    echo "ERROR: Tests failed (exit $TEST_EXIT)"
    exit "$TEST_EXIT"
fi

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"
