#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : fastparquet
# Version          : 2024.11.0
# Source repo      : https://github.com/dask/fastparquet.git
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

PACKAGE_DIR="fastparquet"
PACKAGE_NAME="fastparquet"
PACKAGE_VERSION=${1:-2024.11.0}
PACKAGE_URL="https://github.com/dask/fastparquet.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y \
    gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip \
    make autoconf automake libtool

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

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
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
import fastparquet
from importlib.metadata import version
print('Import successful:', fastparquet.__file__)
print('Version:', version('fastparquet'))
print('Import and version: OK')
"

echo -e "\nTest 2: Basic write (single file, no compression)"
python3.12 - << 'PYEOF'
import os
import pandas as pd
from fastparquet import write

df = pd.DataFrame({
    'col_int':    [1, 2, 3, 4, 5],
    'col_float':  [1.1, 2.2, 3.3, 4.4, 5.5],
    'col_str':    ['a', 'b', 'c', 'd', 'e'],
})

write('/tmp/test_basic.parq', df)
assert os.path.exists('/tmp/test_basic.parq'), "Output file not found"
print("Basic write: OK")
PYEOF

echo -e "\nTest 3: Read and round-trip"
python3.12 - << 'PYEOF'
import pandas as pd
import pandas.testing as tm
from fastparquet import ParquetFile

df_orig = pd.DataFrame({
    'col_int':   [1, 2, 3, 4, 5],
    'col_float': [1.1, 2.2, 3.3, 4.4, 5.5],
    'col_str':   ['a', 'b', 'c', 'd', 'e'],
})

pf = ParquetFile('/tmp/test_basic.parq')
df_read = pf.to_pandas()

assert df_read.shape == df_orig.shape, \
    f"Shape mismatch: {df_read.shape} != {df_orig.shape}"
assert list(df_read.columns) == list(df_orig.columns), \
    f"Column mismatch: {list(df_read.columns)}"
tm.assert_frame_equal(df_read.reset_index(drop=True),
                      df_orig.reset_index(drop=True),
                      check_like=True,
                      check_dtype=False)
print("Read and round-trip: OK")
PYEOF

echo -e "\nTest 4: Column selection"
python3.12 - << 'PYEOF'
from fastparquet import ParquetFile

pf = ParquetFile('/tmp/test_basic.parq')
df = pf.to_pandas(['col_int', 'col_float'])

assert list(df.columns) == ['col_int', 'col_float'], \
    f"Unexpected columns: {list(df.columns)}"
assert 'col_str' not in df.columns, \
    "col_str should not be present after column selection"
print("Column selection: OK")
PYEOF

echo -e "\nTest 5: GZIP compression + multiple row groups"
python3.12 - << 'PYEOF'
import pandas as pd
from fastparquet import write, ParquetFile

df = pd.DataFrame({
    'x': list(range(30)),
    'y': [float(i) * 0.5 for i in range(30)],
})

write('/tmp/test_gzip.parq', df,
      row_group_offsets=[0, 10, 20],
      compression='GZIP')

pf = ParquetFile('/tmp/test_gzip.parq')
assert pf.count() == 30, \
    f"Expected 30 rows, got {pf.count()}"
assert len(pf.row_groups) == 3, \
    f"Expected 3 row groups, got {len(pf.row_groups)}"
print("GZIP compression + multiple row groups: OK")
PYEOF

echo -e "\nTest 6: Hive/directory scheme"
python3.12 - << 'PYEOF'
import shutil, os
import pandas as pd
from fastparquet import write, ParquetFile

hive_dir = '/tmp/test_hive'
if os.path.exists(hive_dir):
    shutil.rmtree(hive_dir)

df = pd.DataFrame({
    'id':    list(range(20)),
    'value': [str(i) for i in range(20)],
})

write(hive_dir, df, file_scheme='hive')
assert os.path.isdir(hive_dir), "Hive output directory not created"

pf = ParquetFile(hive_dir)
df_read = pf.to_pandas()
assert len(df_read) == len(df), \
    f"Row count mismatch: {len(df_read)} != {len(df)}"
print("Hive/directory scheme: OK")
PYEOF

echo -e "\nTest 7: Categorical column encoding"
python3.12 - << 'PYEOF'
import pandas as pd
from fastparquet import write, ParquetFile

# Write the column as a pandas Categorical so fastparquet uses
# dictionary encoding, which is required for categories= on read
df = pd.DataFrame({
    'cat_col': pd.Categorical(['foo', 'bar', 'baz', 'foo', 'bar', 'baz', 'foo']),
    'value':   [1, 2, 3, 4, 5, 6, 7],
})

write('/tmp/test_cat.parq', df)

pf = ParquetFile('/tmp/test_cat.parq')
df_read = pf.to_pandas(categories=['cat_col'])

assert df_read['cat_col'].dtype.name == 'category', \
    f"Expected category dtype, got {df_read['cat_col'].dtype.name}"
print("Categorical column encoding: OK")
PYEOF

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"