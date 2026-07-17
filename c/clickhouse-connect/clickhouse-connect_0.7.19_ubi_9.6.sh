#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : clickhouse-connect
# Version          : 0.7.19
# Source repo      : https://github.com/ClickHouse/clickhouse-connect.git
# Tested on        : UBI 9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ryder Salinas <rbsalinas@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_DIR="clickhouse-connect"
PACKAGE_NAME="clickhouse-connect"
PACKAGE_VERSION=${1:-v0.7.19}
PACKAGE_URL="https://github.com/ClickHouse/clickhouse-connect.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.12 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Build wheel
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "clickhouse_connect-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install "$WHEEL"

# Run tests
echo "=== Running Tests ==="

echo "Test 1: Import and version"
python3.12 -c "
import clickhouse_connect
from importlib.metadata import version
print('Import successful:', clickhouse_connect.__file__)
print('Version:', version('clickhouse_connect'))
print('Import and version: OK')
"

echo "Test 2: Core submodule imports"
python3.12 -c "
from clickhouse_connect.driver import client
from clickhouse_connect.driver.query import QueryResult
from clickhouse_connect.driver.exceptions import ClickHouseError, DatabaseError, OperationalError
from clickhouse_connect.datatypes import registry
print('Core submodule imports: OK')
"

echo "Test 3: Native type system coverage"
python3.12 -c "
from clickhouse_connect.datatypes.numeric import Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, Float32, Float64
from clickhouse_connect.datatypes.string import String, FixedString
from clickhouse_connect.datatypes.temporal import Date, DateTime
from clickhouse_connect.datatypes.container import Array, Tuple
from clickhouse_connect.datatypes.special import UUID
print('Type system coverage: OK')
"

echo "Test 4: Client factory and get_client signature"
python3.12 -c "
import inspect
import clickhouse_connect
sig = inspect.signature(clickhouse_connect.get_client)
params = list(sig.parameters.keys())
for required in ('host', 'port', 'username', 'password'):
    assert required in params, f'Missing expected parameter: {required}'
print('Client factory signature: OK')
print('Parameters:', params)
"

echo "Test 5: QueryResult construction"
python3.12 -c "
from clickhouse_connect.driver.query import QueryResult
qr = QueryResult(
    result_set=[[1, 'foo'], [2, 'bar']],
    column_names=('id', 'name'),
    column_types=(None, None),
    query_id='test-query-id',
    summary={},
)
assert len(qr.result_set) == 2
assert qr.column_names[0] == 'id'
print('QueryResult construction: OK')
"

echo "Test 6: Exception hierarchy"
python3.12 -c "
from clickhouse_connect.driver.exceptions import ClickHouseError, DatabaseError, OperationalError, ProgrammingError
assert issubclass(DatabaseError, ClickHouseError)
assert issubclass(OperationalError, DatabaseError)
assert issubclass(ProgrammingError, DatabaseError)
try:
    raise OperationalError('connection refused')
except ClickHouseError as e:
    print('Exception hierarchy: OK —', e)
"

echo "Test 7: HTTP client class is importable and is a subclass of Client"
python3.12 -c "
from clickhouse_connect.driver.httpclient import HttpClient
from clickhouse_connect.driver.client import Client
assert issubclass(HttpClient, Client)
print('HttpClient hierarchy: OK')
"

echo "Test 8: C extension or pure-Python fallback loads without error"
python3.12 -c "
try:
    from clickhouse_connect.driverc import dataconv
    print('C extension loaded: OK')
except ImportError:
    from clickhouse_connect.driver import dataconv
    print('Pure-Python fallback loaded: OK')
"

echo "Test 9: Compression codecs importable"
python3.12 -c "
from clickhouse_connect.driver.compression import available_compression
print('Available compression codecs:', available_compression)
assert isinstance(available_compression, list)
assert len(available_compression) > 0
print('Compression codecs: OK')
"

echo "Test 10: Settings and common constants"
python3.12 -c "
from clickhouse_connect.driver.common import dict_copy
d = {'a': 1, 'b': 2}
d2 = dict_copy(d, {'c': 3})
assert d2 == {'a': 1, 'b': 2, 'c': 3}
assert 'c' not in d, 'Original dict must not be mutated'
print('dict_copy: OK')
"

echo -e "\n=== Build Complete ==="