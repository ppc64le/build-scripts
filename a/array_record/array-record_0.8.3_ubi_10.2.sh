#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : array-record
# Version          : v0.8.3
# Source repo      : https://github.com/google/array_record
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=array-record
PACKAGE_VERSION=${1:-v0.8.3}
PACKAGE_URL=https://github.com/google/array_record
PACKAGE_DIR=array_record
CURRENT_DIR=$(pwd)

BAZEL_VERSION=7.2.1

# Install system dependencies
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    java-21-openjdk-devel \
    curl rsync zip unzip patch which tar gzip diffutils findutils

# UBI 10 dropped SCL — use the guard block
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

# Locate the OpenJDK 21 home (ppc64le ships it in a versioned path)
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
echo "Using JAVA_HOME: ${JAVA_HOME}"
echo "Using java: $(java -version 2>&1 | head -1)"

# Upgrade pip and install Python build tools
pip3.14 install --upgrade pip setuptools wheel

# ---------------------------------------------------------------------------
# Bootstrap Bazel 7.2.1 from the official dist.zip (ppc64le has no pre-built
# binary)
# ---------------------------------------------------------------------------
BAZEL_DIST_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
BAZEL_BUILD_DIR="/tmp/bazel-${BAZEL_VERSION}-build"

echo "=== Downloading Bazel ${BAZEL_VERSION} dist.zip ==="
rm -rf "${BAZEL_BUILD_DIR}"
mkdir -p "${BAZEL_BUILD_DIR}"
curl -sSL --fail -o "${BAZEL_BUILD_DIR}/bazel-dist.zip" "${BAZEL_DIST_URL}"

cd "${BAZEL_BUILD_DIR}"
unzip -q -o bazel-dist.zip

echo "=== Patching missing #include <cstdint> for GCC strict headers ==="
for f in \
    src/main/cpp/archive_utils.h \
    src/main/cpp/blaze.h \
    src/main/cpp/blaze_util.h \
    src/main/cpp/startup_options.h \
    src/main/cpp/util/numbers.h; do
    if [[ -f "$f" ]]; then
        sed -i '1s/^/#include <cstdint>\n/' "$f"
        echo "  patched: $f"
    fi
done

echo "=== Running compile.sh ==="
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" \
    JAVA_HOME="${JAVA_HOME}" \
    bash compile.sh

cp output/bazel /usr/local/bin/bazel
chmod a+x /usr/local/bin/bazel
cd "${CURRENT_DIR}"
echo "Using Bazel: $(bazel version 2>&1 | grep -i 'build label')"

# Install Python dependencies for array-record
pip3.14 install absl-py "etils[epath]" auditwheel patchelf setuptools wheel

# Clone source
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Set up Bazel configuration
PYTHON_BIN="$(which python3.14)"
PYTHON_VERSION="3.14"
PYTHON_MINOR_VERSION="14"

[ -e .bazelrc ] && rm .bazelrc

cat >> .bazelrc <<EOF
build --incompatible_default_to_explicit_init_py
build --enable_platform_specific_config
build --@rules_python//python/config_settings:python_version=${PYTHON_VERSION}
test --@rules_python//python/config_settings:python_version=${PYTHON_VERSION}
test --action_env PYTHON_VERSION=${PYTHON_VERSION}
test --test_timeout=300
build -c opt
build --cxxopt=-std=c++17
build --host_cxxopt=-std=c++17
build --experimental_repo_remote_exec
common --check_direct_dependencies=error
build --cxxopt=-Wno-deprecated-declarations --host_cxxopt=-Wno-deprecated-declarations
build --cxxopt=-Wno-parentheses --host_cxxopt=-Wno-parentheses
build --cxxopt=-Wno-sign-compare --host_cxxopt=-Wno-sign-compare
# ppc64le: no prebuilt CPython — disable hermetic Python CC toolchain so
# rules_python falls back to the system Python headers
build --noincompatible_use_python_toolchains
build --action_env PYTHON_BIN_PATH=${PYTHON_BIN}
build --action_env PYTHON_INCLUDE_PATH=/usr/include/python${PYTHON_VERSION}
build --action_env PYTHON_LIB_PATH=/usr/lib64
EOF

# ---------------------------------------------------------------------------
# Create a stub for rules_buf — it tries to download ppc64le toolchains which
# don't exist. We stub it out with an empty module so it resolves but never
# tries to fetch any binaries.
# ---------------------------------------------------------------------------
RULES_BUF_STUB="/tmp/dep_overrides/rules_buf"
mkdir -p "${RULES_BUF_STUB}"
cat > "${RULES_BUF_STUB}/MODULE.bazel" <<'EOF_BUF'
module(name = "rules_buf", version = "0.3.0")
bazel_dep(name = "platforms", version = "0.0.4")
bazel_dep(name = "rules_proto", version = "5.3.0-21.7")
bazel_dep(name = "bazel_skylib", version = "1.5.0")
EOF_BUF
touch "${RULES_BUF_STUB}/WORKSPACE"

# Patch MODULE.bazel: narrow to Python 3.14 only, replace list-comprehensions
# with single explicit calls, add local_path_override for rules_buf stub,
# and register the system Python CC toolchain.
python3.14 - "${PYTHON_BIN}" "${PYTHON_VERSION}" <<'PYEOF'
import sys, re
python_bin, python_version = sys.argv[1:]

data = open('MODULE.bazel').read()

# 1. Narrow version lists
data = re.sub(
    r'SUPPORTED_PYTHON_VERSIONS\s*=\s*\[[^\]]*\]',
    f'SUPPORTED_PYTHON_VERSIONS = ["{python_version}"]',
    data, flags=re.DOTALL
)
data = re.sub(
    r'DEFAULT_PYTHON_VERSION\s*=\s*"[^"]*"',
    f'DEFAULT_PYTHON_VERSION = "{python_version}"',
    data
)

# 2. Replace python.toolchain list-comprehension
data = re.sub(
    r'\[\s*\n\s*python\.toolchain\([^)]*\)\s*\n\s*for python_version in SUPPORTED_PYTHON_VERSIONS\s*\]\n?',
    (f'python.toolchain(\n'
     f'    ignore_root_user_error = True,\n'
     f'    is_default = True,\n'
     f'    python_version = "{python_version}",\n'
     f')\n'),
    data, flags=re.DOTALL
)

# 3. Replace pip.parse list-comprehension with single explicit call for 3.14
req_lock = "test_requirements_lock_{}.txt".format(python_version.replace(".", "_"))
data = re.sub(
    r'\[\s*\n\s*pip\.parse\(.*?\)\s*\n\s*for version in SUPPORTED_PYTHON_VERSIONS\s*\]\n?',
    (f'pip.parse(\n'
     f'    hub_name = "pypi",\n'
     f'    python_version = "{python_version}",\n'
     f'    python_interpreter = "{python_bin}",\n'
     f'    requirements_lock = "{req_lock}",\n'
     f')\n'),
    data, flags=re.DOTALL
)

# 4. Add local_path_override for rules_buf stub
overrides = (
    f'local_path_override(\n    module_name = "rules_buf",\n    path = "/tmp/dep_overrides/rules_buf",\n)\n\n'
)
data = re.sub(r'(bazel_dep\(name = "rules_proto")', overrides + r'\1', data, count=1)

# 5. Register the system Python CC toolchain
data += '\nregister_toolchains("//tools/python_cc:py_cc_toolchain_def")\n'

open('MODULE.bazel', 'w').write(data)
print(f'MODULE.bazel patched — rules_buf overridden, Python {python_version}')
PYEOF

# Create a local Python CC toolchain backed by the system Python headers.
PYTHON_INCLUDE_DIR="/usr/include/python${PYTHON_VERSION}"
cat >> WORKSPACE.bazel <<WSEOF

# System Python headers for ppc64le py_cc_toolchain (no hermetic CPython here)
new_local_repository(
    name = "system_python",
    path = "${PYTHON_INCLUDE_DIR}",
    build_file_content = """
cc_library(
    name = "python_headers",
    hdrs = glob(["*.h", "cpython/*.h", "internal/*.h"], allow_empty = True),
    includes = ["."],
    visibility = ["//visibility:public"],
)
""",
)
WSEOF

mkdir -p tools/python_cc
cat > tools/python_cc/BUILD.bazel <<'TOOLCHAIN_EOF'
load("@rules_python//python/cc:py_cc_toolchain.bzl", "py_cc_toolchain")

py_cc_toolchain(
    name = "py_cc_toolchain",
    headers = "@system_python//:python_headers",
    python_version = "PYTHON_VERSION_PLACEHOLDER",
)

toolchain(
    name = "py_cc_toolchain_def",
    toolchain = ":py_cc_toolchain",
    toolchain_type = "@rules_python//python/cc:toolchain_type",
)
TOOLCHAIN_EOF
sed -i "s/PYTHON_VERSION_PLACEHOLDER/${PYTHON_VERSION}/" tools/python_cc/BUILD.bazel

# ---------------------------------------------------------------------------
# Fetch deps (pass 1): populates rules_python into the cache so we can patch
# extension.bzl. The pip extension will fail for non-3.14 Python versions on
# ppc64le — that is expected and ignored via || true.
# ---------------------------------------------------------------------------
echo "=== Pre-fetching Bazel module deps (pass 1 — populate rules_python cache) ==="
bazel fetch //cpp/... //python/... \
    --action_env PYTHON_BIN_PATH="${PYTHON_BIN}" || true

EXTENSION_BZL_CACHE=$(find "${HOME}/.cache/bazel" -path "*/external/rules_python~/python/private/pypi/extension.bzl" 2>/dev/null | head -1)
if [[ -z "${EXTENSION_BZL_CACHE}" ]]; then
    echo "ERROR: rules_python extension.bzl not found in Bazel cache after fetch"
    exit 1
fi
echo "=== Patching rules_python extension.bzl in cache: ${EXTENSION_BZL_CACHE} ==="
python3.14 - "${EXTENSION_BZL_CACHE}" "${PYTHON_BIN}" <<'PYEOF'
import sys
path, python_bin = sys.argv[1], sys.argv[2]
data = open(path).read()

ALREADY_PATCHED = '# ppc64le: no prebuilt CPython binary — return empty hub for this version'
if ALREADY_PATCHED in data:
    print(f'extension.bzl already patched — skipping')
    sys.exit(0)

old = '''        if python_name not in available_interpreters:
            fail((
                "Unable to find interpreter for pip hub '{hub_name}' for " +
                "python_version={version}: Make sure a corresponding " +
                '`python.toolchain(python_version="{version}")` call exists.' +
                "Expected to find {python_name} among registered versions:\\n  {labels}"
            ).format(
                hub_name = hub_name,
                version = pip_attr.python_version,
                python_name = python_name,
                labels = "  \\n".join(available_interpreters),
            ))
        python_interpreter_target = available_interpreters[python_name]'''

new = '''        if python_name not in available_interpreters:
            # ppc64le: no prebuilt CPython binary — return empty hub for this version
            return struct(
                whl_map = {},
                exposed_packages = {},
                whl_libraries = {},
                extra_aliases = {},
            )
        python_interpreter_target = available_interpreters[python_name]'''

if old in data:
    data = data.replace(old, new)
    open(path, 'w').write(data)
    print(f'Patched {path} — ppc64le fallback interpreter injected')
else:
    print(f'WARNING: expected pattern not found in {path} — check rules_python version')
    sys.exit(1)
PYEOF

# ---------------------------------------------------------------------------
# Fetch deps (pass 2): now that extension.bzl is patched, fetch succeeds and
# populates boringssl, highwayhash, and all remaining external repos.
# ---------------------------------------------------------------------------
echo "=== Pre-fetching Bazel module deps (pass 2 — populate all remaining externals) ==="
bazel fetch //cpp/... //python/... \
    --action_env PYTHON_BIN_PATH="${PYTHON_BIN}" || true

# ---------------------------------------------------------------------------
# Patch BoringSSL target.h in the Bazel cache to add ppc64le CPU detection.
# BoringSSL's target.h does not recognise __powerpc64__ so every source file
# that includes <openssl/base.h> fails with "#error Unknown target CPU".
# ---------------------------------------------------------------------------
BORINGSSL_TARGET_H=$(find "${HOME}/.cache/bazel" -path "*/external/boringssl~/include/openssl/target.h" 2>/dev/null | head -1)
if [[ -n "${BORINGSSL_TARGET_H}" ]]; then
    if grep -q 'OPENSSL_PPC64LE' "${BORINGSSL_TARGET_H}"; then
        echo "=== BoringSSL target.h already patched for ppc64le — skipping ==="
    else
        echo "=== Patching BoringSSL target.h for ppc64le: ${BORINGSSL_TARGET_H} ==="
        python3.14 - "${BORINGSSL_TARGET_H}" <<'PYEOF'
import sys
path = sys.argv[1]
data = open(path).read()
old = '#elif defined(__myriad2__)\n#define OPENSSL_32_BIT\n#else\n'
new = ('#elif defined(__myriad2__)\n#define OPENSSL_32_BIT\n'
       '#elif defined(__powerpc64__) && defined(__LITTLE_ENDIAN__)\n'
       '#define OPENSSL_64_BIT\n#define OPENSSL_PPC64LE\n'
       '#elif defined(__powerpc64__)\n'
       '#define OPENSSL_64_BIT\n#define OPENSSL_PPC64\n'
       '#else\n')
if old in data:
    data = data.replace(old, new)
    open(path, 'w').write(data)
    print(f'Patched {path} — ppc64le inserted after __myriad2__')
else:
    print(f'WARNING: expected pattern not found in {path}')
    sys.exit(1)
PYEOF
        echo "  patched: ${BORINGSSL_TARGET_H}"
    fi
else
    echo "WARNING: BoringSSL target.h not found in cache — skipping patch"
fi

# ---------------------------------------------------------------------------
# Patch highwayhash BUILD.bazel in the Bazel cache to add cpu_ppc to the
# highwayhash_dynamic target and add -mvsx/-maltivec copts to hh_vsx.
# ---------------------------------------------------------------------------
HIGHWAYHASH_BUILD=$(find "${HOME}/.cache/bazel" -path "*/external/highwayhash~/BUILD.bazel" 2>/dev/null | head -1)
if [[ -n "${HIGHWAYHASH_BUILD}" ]]; then
    if grep -q '\-mvsx' "${HIGHWAYHASH_BUILD}" 2>/dev/null; then
        echo "=== highwayhash BUILD.bazel already patched for ppc64le — skipping ==="
    else
        echo "=== Patching highwayhash BUILD.bazel for ppc64le cpu_ppc + -mvsx ==="
        python3.14 - "${HIGHWAYHASH_BUILD}" <<'PYEOF'
import sys, re
path = sys.argv[1]
data = open(path).read()
old1 = '''    name = "highwayhash_dynamic",
    hdrs = ["highwayhash/highwayhash_target.h"],
    deps = [
        ":arch_specific",
        ":compiler_specific",
        ":hh_portable",
        ":hh_types",
    ] + select({
        ":cpu_aarch64": [":hh_neon"],
        ":cpu_darwin_arm64": [":hh_neon"],
        "//conditions:default": [
            ":hh_avx2",
            ":hh_sse41",
        ],
    }),
)'''
new1 = '''    name = "highwayhash_dynamic",
    hdrs = ["highwayhash/highwayhash_target.h"],
    deps = [
        ":arch_specific",
        ":compiler_specific",
        ":hh_portable",
        ":hh_types",
    ] + select({
        ":cpu_ppc": [":hh_vsx"],
        ":cpu_aarch64": [":hh_neon"],
        ":cpu_darwin_arm64": [":hh_neon"],
        "//conditions:default": [
            ":hh_avx2",
            ":hh_sse41",
        ],
    }),
)'''
old2 = '''cc_library(
    name = "hh_vsx",
    srcs = ["highwayhash/hh_vsx.cc"],
    hdrs = ["highwayhash/highwayhash_target.h"],
    textual_hdrs = ['''
new2 = '''cc_library(
    name = "hh_vsx",
    srcs = ["highwayhash/hh_vsx.cc"],
    hdrs = ["highwayhash/highwayhash_target.h"],
    copts = ["-mvsx", "-maltivec"],
    textual_hdrs = ['''
changed = False
if old1 in data:
    data = data.replace(old1, new1)
    changed = True
    print(f'Patched {path} — cpu_ppc added to highwayhash_dynamic')
else:
    print(f'WARNING: highwayhash_dynamic pattern not found in {path}')
    sys.exit(1)
if old2 in data:
    data = data.replace(old2, new2, 1)
    changed = True
    print(f'Patched {path} — -mvsx copts added to hh_vsx')
else:
    print(f'WARNING: hh_vsx pattern not found in {path}')
    sys.exit(1)
if changed:
    open(path, 'w').write(data)
PYEOF
        echo "  patched: ${HIGHWAYHASH_BUILD}"
    fi
else
    echo "WARNING: highwayhash BUILD.bazel not found in cache — skipping patch"
fi

export USE_BAZEL_VERSION="${BAZEL_VERSION}"

# Build with Bazel — target cpp and python packages explicitly
if ! bazel build //cpp/... //python/... \
        --action_env PYTHON_BIN_PATH="${PYTHON_BIN}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Assemble the wheel from Bazel build outputs
DEST="${CURRENT_DIR}/all_dist"
mkdir -p "${DEST}"
TMPDIR=$(mktemp -d -t tmp.XXXXXXXXXX)
mkdir "${TMPDIR}/array_record"

cp setup.py "${TMPDIR}"
cp LICENSE "${TMPDIR}"
rsync -avm -L --exclude="bazel-*/" . "${TMPDIR}/array_record"
rsync -avm -L \
    --include="*.so" --include="*_pb2.py" \
    --exclude="*.runfiles" --exclude="*_obj" --include="*/" --exclude="*" \
    bazel-bin/cpp "${TMPDIR}/array_record"
rsync -avm -L \
    --include="*.so" --include="*_pb2.py" \
    --exclude="*.runfiles" --exclude="*_obj" --include="*/" --exclude="*" \
    bazel-bin/python "${TMPDIR}/array_record"

pushd "${TMPDIR}"
if ! "${PYTHON_BIN}" setup.py bdist_wheel \
        --python-tag "py3${PYTHON_MINOR_VERSION}"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
popd

# Repair wheel with auditwheel — use manylinux_2_39_ppc64le to match glibc 2.39
# on UBI 10.2. manylinux2014 requires glibc < 2.28 symbols which GCC 15 exceeds.
AUDITWHEEL_PLATFORM="manylinux_2_39_ppc64le"
auditwheel repair --plat "${AUDITWHEEL_PLATFORM}" \
    -w "${DEST}" "${TMPDIR}/dist/"*.whl
# Install from the repaired wheel — use python -m pip to avoid pip 25.x file:// bug
REPAIRED_WHL=$(ls "${DEST}/"*manylinux*.whl | head -1)
python3.14 -m pip install "${REPAIRED_WHL}"

if ! python3.14 -c "
import array_record
from array_record.python import array_record_data_source
print('array_record import OK')
print('array_record_data_source import OK')
"; then
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
