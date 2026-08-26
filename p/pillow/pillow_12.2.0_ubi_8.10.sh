#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Pillow
# Version       : 12.2.0
# Source repo   : https://github.com/python-pillow/Pillow.git
# Tested on     : UBI 8.10
# Language      : Python, C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package. It may not work
# as expected with newer versions of the package and/or distribution.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=Pillow
PACKAGE_VERSION=${1:-12.2.0}
PACKAGE_URL=https://github.com/python-pillow/Pillow.git
PACKAGE_DIR=Pillow
CURRENT_DIR=${PWD}

# -----------------------------------------------------------------------------
# 1. Install system dependencies
# -----------------------------------------------------------------------------

# Core build tools and GCC Toolset 13 (same toolchain as Pandas/NumPy builds)
yum install -y python3.12 python3.12-devel python3.12-pip git make binutils wget gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ pkg-config zlib-devel libjpeg-turbo-devel libpng-devel libtiff-devel freetype-devel libwebp-devel xz-devel libffi-devel

# UBI 8.10 ships GCC 8.5.
# GCC Toolset 13 provides GCC 13 — same toolchain used by the Pandas/NumPy builds.
source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

echo "GCC version: $(gcc --version | head -1)"
echo "Python version: $(python3.12 --version)"

# -----------------------------------------------------------------------------
# 2. Clone source repository
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d "$PACKAGE_DIR" ] && rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"

# -----------------------------------------------------------------------------
# 3. Set package version
# -----------------------------------------------------------------------------

# IBM local version label (PEP 440: 12.2.0+ppc64le1)
# Injected via env var — setup files are NOT modified.
export SETUPTOOLS_SCM_PRETEND_VERSION="${PACKAGE_VERSION}+ppc64le1"

echo "Package version: ${PACKAGE_VERSION}"
echo "Full version: ${SETUPTOOLS_SCM_PRETEND_VERSION}"

# -----------------------------------------------------------------------------
# 4. Create Python virtual environment
# -----------------------------------------------------------------------------

PYTHON_BIN=$(command -v python3.12 || command -v python3 || command -v python)
"${PYTHON_BIN}" -m venv pillow-env
source pillow-env/bin/activate
PYTHON_BIN="${VIRTUAL_ENV}/bin/python"

echo "Using Python: ${PYTHON_BIN}"
echo "Python version: $(${PYTHON_BIN} --version)"

# -----------------------------------------------------------------------------
# 5. Install Python build dependencies
# -----------------------------------------------------------------------------

"${PYTHON_BIN}" -m pip install --upgrade pip wheel setuptools
"${PYTHON_BIN}" -m pip install build pytest auditwheel patchelf pybind11

# -----------------------------------------------------------------------------
# 6. Configure Power compiler flags
# -----------------------------------------------------------------------------

# Power9-compatible code that also runs on Power9, Power10, and Power11.
# -mcpu=native and Power10/Power11-only instructions are intentionally omitted
# to ensure the wheel works across the full supported Power CPU range.
export CFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CXXFLAGS="-mcpu=power9 -mtune=power9 -O2"

echo "CFLAGS=${CFLAGS}"
echo "CXXFLAGS=${CXXFLAGS}"

# -----------------------------------------------------------------------------
# 7. Verify that native image-library headers are present
# -----------------------------------------------------------------------------

echo "Verifying native image library headers..."

for header in jpeglib.h png.h tiff.h ft2build.h; do
    find /usr/include /usr/local/include -name "${header}" 2>/dev/null | grep -q . \
        && echo "  OK: ${header}" \
        || echo "WARNING: Header not found: ${header} — the corresponding Pillow codec will be disabled."
done

# -----------------------------------------------------------------------------
# 8. Build Pillow wheel
# -----------------------------------------------------------------------------

# MAX_CONCURRENCY keeps the build from exhausting memory on a large POWER box.
export MAX_CONCURRENCY=${MAX_CONCURRENCY:-4}

if "${PYTHON_BIN}" -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Build_Success"
else
    echo "------------------$PACKAGE_NAME::Build_Fail---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Build_Fail"
    exit 1
fi

# -----------------------------------------------------------------------------
# 9. Verify source wheel
# -----------------------------------------------------------------------------

SOURCE_WHEEL=$(ls dist/pillow-*.whl dist/Pillow-*.whl 2>/dev/null | head -1)

if [ -z "${SOURCE_WHEEL}" ] || [ ! -f "${SOURCE_WHEEL}" ]; then
    echo "ERROR: Pillow source wheel not found"
    exit 1
fi

echo "Source wheel: ${SOURCE_WHEEL}"

# -----------------------------------------------------------------------------
# 10. Run auditwheel
#
# auditwheel repair bundles all non-system .so dependencies that exceed the
# manylinux_2_28 ABI baseline into the wheel and re-tags the platform tag
# to manylinux_2_28_ppc64le.
# -----------------------------------------------------------------------------

mkdir -p wheelhouse
rm -f wheelhouse/pillow-*.whl wheelhouse/Pillow-*.whl

echo "Running auditwheel repair..."

if auditwheel repair --plat manylinux_2_28_ppc64le --wheel-dir wheelhouse "${SOURCE_WHEEL}"; then
    echo "------------------$PACKAGE_NAME::Auditwheel_Pass---------------------"
    echo "Auditwheel repair successful"
else
    echo "------------------$PACKAGE_NAME::Auditwheel_Fail---------------------"
    echo "Auditwheel repair failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# 11. Find repaired wheel
# -----------------------------------------------------------------------------

DUAL_WHEEL=$(ls wheelhouse/pillow-*.whl wheelhouse/Pillow-*.whl 2>/dev/null | head -1)

if [ -z "${DUAL_WHEEL}" ] || [ ! -f "${DUAL_WHEEL}" ]; then
    echo "ERROR: Repaired Pillow wheel not found"
    exit 1
fi

echo "Auditwheel generated wheel: ${DUAL_WHEEL}"

# -----------------------------------------------------------------------------
# 12. Extract tags, construct and finalise wheel name
#
# Tags are extracted from SOURCE_WHEEL (not DUAL_WHEEL) because auditwheel
# may produce a non-standard filename in this environment.
# Example: Pillow-12.2.0+ppc64le1-cp312-cp312-linux_ppc64le.whl
# -----------------------------------------------------------------------------

SOURCE_BASENAME=$(basename "${SOURCE_WHEEL}")
VERSION=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f2)
PYTHON_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f3)
ABI_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f4)

echo "Version: ${VERSION} | Python tag: ${PYTHON_TAG} | ABI tag: ${ABI_TAG}"

if [ -z "${VERSION}" ] || [ -z "${PYTHON_TAG}" ] || [ -z "${ABI_TAG}" ]; then
    echo "ERROR: Unable to extract wheel metadata from source wheel"
    exit 1
fi

FINAL_WHEEL="wheelhouse/Pillow-${VERSION}-${PYTHON_TAG}-${ABI_TAG}-manylinux_2_28_ppc64le.whl"

if [ "${DUAL_WHEEL}" != "${FINAL_WHEEL}" ]; then
    [ -f "${FINAL_WHEEL}" ] && { echo "ERROR: Final wheel already exists: ${FINAL_WHEEL}"; exit 1; }
    mv "${DUAL_WHEEL}" "${FINAL_WHEEL}"
    echo "Renamed wheel: $(basename "${FINAL_WHEEL}")"
else
    echo "Wheel already has the expected filename: $(basename "${FINAL_WHEEL}")"
fi

[ -f "${FINAL_WHEEL}" ] || { echo "ERROR: Final wheel not found: ${FINAL_WHEEL}"; exit 1; }
echo "Final wheel ready: ${FINAL_WHEEL}"

# -----------------------------------------------------------------------------
# 13. Install generated wheel
# -----------------------------------------------------------------------------

if "${PYTHON_BIN}" -m pip install --only-binary=:all: "${FINAL_WHEEL}"; then
    echo "------------------$PACKAGE_NAME::Install_Pass---------------------"
else
    echo "------------------$PACKAGE_NAME::Install_Fail---------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# 14. Test installed Pillow
# -----------------------------------------------------------------------------

cd ..

"${PYTHON_BIN}" -m pip show Pillow

"${PYTHON_BIN}" -c "
import sys, tempfile, shutil
from pathlib import Path
from PIL import Image, ImageDraw, features

print('Version :', Image.__version__)
print('Location:', Image.__file__)
print()
features.pilinfo(out=sys.stdout)
print()

def make_test_image():
    img = Image.new('RGB', (64, 64), (255, 0, 128))
    ImageDraw.Draw(img).rectangle([4, 4, 60, 60], outline=(0, 255, 0), width=2)
    return img

TMPDIR = Path(tempfile.mkdtemp())
img = make_test_image()

for fmt, path, kw in [
    ('PNG',  TMPDIR / 'test.png',  {}),
    ('JPEG', TMPDIR / 'test.jpg',  {'quality': 90}),
    ('TIFF', TMPDIR / 'test.tiff', {}),
]:
    img.save(str(path), **kw)
    r = Image.open(str(path)); r.load()
    assert r.size == (64, 64) and r.mode == 'RGB', f'{fmt} round-trip failed'
    print(f'{fmt} round-trip:  PASSED')

if features.check('webp'):
    p = TMPDIR / 'test.webp'
    img.save(str(p)); r = Image.open(str(p)); r.load()
    assert r.size == (64, 64), 'WebP round-trip failed'
    print('WebP round-trip: PASSED')
else:
    print('WebP round-trip: SKIPPED (codec not available)')

assert img.resize((16, 16), Image.LANCZOS).size == (16, 16), 'resize failed'
print('Resize:          PASSED')

assert img.rotate(45, expand=True).size != (0, 0), 'rotate failed'
print('Rotate:          PASSED')

assert img.convert('L').mode == 'L' and img.convert('CMYK').mode == 'CMYK', 'convert failed'
print('Colour convert:  PASSED')

shutil.rmtree(str(TMPDIR))
print()
print('All Pillow functional tests PASSED.')
"

if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Test_Success"
    deactivate
    exit 0
else
    echo "------------------$PACKAGE_NAME::Test_Fail---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Test_Fail"
    deactivate
    exit 2
fi
