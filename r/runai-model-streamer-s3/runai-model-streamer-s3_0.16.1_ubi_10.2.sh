#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : runai-model-streamer-s3
# Version       : 0.16.1
# Source repo   : https://github.com/run-ai/runai-model-streamer
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
#
# Builds the S3 extension wheel only:
#   runai_model_streamer_s3-<version>-py3-none-manylinux2014_ppc64le.whl
#
# This wheel contains libstreamers3.so (the S3 backend plugin) and the boto3-
# based Python credential/file helpers.  It requires the core wheel
# (runai-model-streamer) to already be installed, and requires aws-sdk-cpp to
# be built and installed under /usr/local before the Bazel build runs.
#
# Run the companion script first if needed:
#   runai-model-streamer_0.16.1_ubi_10.2_wheel1_core.sh
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=runai-model-streamer-s3
PACKAGE_VERSION=${1:-0.16.1}
PACKAGE_URL=https://github.com/run-ai/runai-model-streamer
PACKAGE_DIR=runai-model-streamer
CURRENT_DIR=$(pwd)

BAZEL_VERSION="7.6.1"

# Install dependencies
yum install -y python3.12 python3.12-devel \
    git gcc gcc-c++ gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build \
    java-21-openjdk-devel \
    libcurl-devel openssl-devel libuuid-devel \
    unzip zip patch

# Configure GCC Toolset 15
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

# Configure Java
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms200m"
export PATH="$JAVA_HOME/bin:$PATH"
export PACKAGE_VERSION

# Install Python build tools
pip install --upgrade pip setuptools wheel

# Install Python runtime dependencies.
# boto3 is the sole runtime dep of this wheel.
# torch, humanize, numpy are required because the core wheel (which must already
# be installed) imports them at module level — pip validates them on install.
# safetensors is needed for the test stage.
# torch has no ppc64le wheel on PyPI — install from the IBM wheels index.
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
pip install --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary \
    torch
pip install humanize "numpy>=1.24.4" "safetensors>=0.5.3" boto3

# ---------------------------------------------------------------------------
# Step 0: Bootstrap Bazel from source
# No pre-built Bazel binary exists for ppc64le. We bootstrap from the official
# source distribution (dist.zip), which only requires a JDK and a C++ compiler.
# The compiled binary is installed to /usr/local/bin/bazel.
# ---------------------------------------------------------------------------
SKIP_BAZEL_BUILD=0

if [[ -x /usr/local/bin/bazel ]]; then
    INSTALLED_VER="$(/usr/local/bin/bazel version 2>/dev/null | awk '/Build label/{print $NF}')"
    if [[ "$INSTALLED_VER" == "$BAZEL_VERSION" ]]; then
        echo "==> Bazel $BAZEL_VERSION already installed at /usr/local/bin/bazel — skipping bootstrap"
        SKIP_BAZEL_BUILD=1
    fi
fi

if [[ "$SKIP_BAZEL_BUILD" -eq 0 ]]; then
    BAZEL_DIST_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_DIST_ZIP="$CURRENT_DIR/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_BUILD_DIR="$CURRENT_DIR/bazel-${BAZEL_VERSION}-src"

    echo "==> Downloading Bazel $BAZEL_VERSION source distribution"
    [[ -f "$BAZEL_DIST_ZIP" ]] \
        || curl -fL "$BAZEL_DIST_URL" -o "$BAZEL_DIST_ZIP"

    echo "==> Extracting Bazel source distribution"
    if [[ ! -d "$BAZEL_BUILD_DIR" ]]; then
        mkdir -p "$BAZEL_BUILD_DIR"
        unzip -q "$BAZEL_DIST_ZIP" -d "$BAZEL_BUILD_DIR"
    fi

    echo "==> Bootstrapping Bazel (this may take 10-20 minutes)"
    cd "$BAZEL_BUILD_DIR"
    # Bazel 7.6.1 sources are not compatible with GCC 15 (missing <cstdint>
    # transitive includes). The system gcc/g++ installed above (gcc + gcc-c++)
    # builds Bazel cleanly. We temporarily shadow the toolset-15 gcc/g++ with
    # the system versions just for this bootstrap, then restore PATH afterwards.
    ulimit -u unlimited 2>/dev/null || ulimit -u 65536 2>/dev/null || true
    SAVED_PATH="$PATH"
    export PATH="/usr/bin:/usr/sbin:${PATH}"
    export CC=/usr/bin/gcc
    export CXX=/usr/bin/g++
    export EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs=4"
    bash compile.sh
    export PATH="$SAVED_PATH"
    unset CC CXX

    install -m 0755 output/bazel /usr/local/bin/bazel
    echo "==> Bazel installed: $(bazel version 2>/dev/null | head -1)"
    cd "$CURRENT_DIR"
fi

# ---------------------------------------------------------------------------
# Step 1: Clone the repository and checkout the requested version
# ---------------------------------------------------------------------------
echo "==> Cloning runai-model-streamer"
if [[ ! -d "$CURRENT_DIR/$PACKAGE_DIR" ]]; then
    git clone $PACKAGE_URL $CURRENT_DIR/$PACKAGE_DIR
fi

cd "$CURRENT_DIR/$PACKAGE_DIR"

echo "==> Checking out version $PACKAGE_VERSION"
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '$PACKAGE_VERSION' (tried v${PACKAGE_VERSION} and ${PACKAGE_VERSION})"
    exit 1
fi

echo "==> HEAD commit: $(git log --oneline -1)"

# ---------------------------------------------------------------------------
# Step 2: Patch top-level Makefile
# The upstream Makefile uses TABS for recipe indentation.
# "build:" has a trailing space: "build: "
# ---------------------------------------------------------------------------
echo "==> Patching Makefile (ppc64le arch + build target)"

python3 - <<'PYEOF'
path = "Makefile"
with open(path) as fh:
    src = fh.read()

changed = False

if "PPC64LE_ARCH" not in src:
    src = src.replace(
        "AARCH64_ARCH := aarch64",
        "AARCH64_ARCH := aarch64\nPPC64LE_ARCH := ppc64le"
    )
    changed = True

OLD_AARCH64 = (
    "build_aarch64:\n"
    "\tmake -C cpp build ARCH=${AARCH64_ARCH} && \\\n"
    "\tmake -C py build ARCH=${AARCH64_ARCH}"
)
NEW_AARCH64_PLUS_PPC = (
    "build_aarch64:\n"
    "\tmake -C cpp build ARCH=${AARCH64_ARCH} && \\\n"
    "\tmake -C py build ARCH=${AARCH64_ARCH}\n"
    "\n"
    "build_ppc64le:\n"
    "\tmake -C cpp build ARCH=${PPC64LE_ARCH} && \\\n"
    "\tmake -C py build ARCH=${PPC64LE_ARCH}"
)
if "build_ppc64le:" not in src:
    if OLD_AARCH64 in src:
        src = src.replace(OLD_AARCH64, NEW_AARCH64_PLUS_PPC)
        changed = True
    else:
        print("  WARNING: could not find build_aarch64 block — dumping for diagnosis:")
        idx = src.find("build_aarch64")
        print(repr(src[idx:idx+200]) if idx >= 0 else "  (not found)")

OLD_BUILD = (
    "build: \n"
    "\tmake -C py clean && \\\n"
    "\tmake build_x86_64 && \\\n"
    "\tmake build_aarch64"
)
NEW_BUILD = (
    "build: \n"
    "\tmake -C py clean && \\\n"
    "\tmake build_ppc64le"
)
if NEW_BUILD not in src:
    if OLD_BUILD in src:
        src = src.replace(OLD_BUILD, NEW_BUILD)
        changed = True
    else:
        print("  WARNING: could not find expected build: recipe — dumping for diagnosis:")
        idx = src.find("build:")
        print(repr(src[idx:idx+200]) if idx >= 0 else "  (not found)")

with open(path, "w") as fh:
    fh.write(src)
print("  Makefile patched OK" if changed else "  Makefile already fully patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 3: Patch cpp/.bazelrc (ppc64le platform suffix)
# ---------------------------------------------------------------------------
echo "==> Patching cpp/.bazelrc (ppc64le platform suffix)"

python3 - <<'PYEOF'
path = "cpp/.bazelrc"
with open(path) as fh:
    src = fh.read()

if "build:ppc64le" not in src:
    src = src.rstrip("\n") + "\n\nbuild:ppc64le --platform_suffix=ppc64le\n"
    with open(path, "w") as fh:
        fh.write(src)
    print("  cpp/.bazelrc patched OK")
else:
    print("  cpp/.bazelrc already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 4: Patch cpp/cc/freeres/freeres.cc
# Removes the hidden visibility attribute that causes link errors on ppc64le.
# ---------------------------------------------------------------------------
echo "==> Patching cpp/cc/freeres/freeres.cc (__freeres visibility)"

python3 - <<'PYEOF'
path = "cpp/cc/freeres/freeres.cc"
with open(path) as fh:
    src = fh.read()

old = '    __attribute__((visibility("hidden"))) void __freeres();'
new = '    void __freeres();'
if old in src:
    src = src.replace(old, new)
    with open(path, "w") as fh:
        fh.write(src)
    print("  freeres.cc patched OK")
else:
    print("  freeres.cc already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 5: Patch cpp/third_party/aws.bzl (linkopts)
# Replaces the original static-only linkopts with a dynamic/static select()
# block that also adds the /usr/local/lib64 search path for the system-installed
# aws-sdk-cpp.
# ---------------------------------------------------------------------------
echo "==> Patching cpp/third_party/aws.bzl (linkopts)"

python3 - <<'PYEOF'
path = "cpp/third_party/aws.bzl"
with open(path) as fh:
    src = fh.read()

if '"-L/usr/local/lib64"' in src:
    print("  aws.bzl already patched — skipping")
    raise SystemExit(0)

OLD_LINKOPTS = (
    "        linkopts = [\n"
    '            "-lpthread",\n'
    '            "-l:libaws-cpp-sdk-s3-crt.a",\n'
    '            "-l:libaws-cpp-sdk-core.a",\n'
    '            "-l:libaws-crt-cpp.a",\n'
    '            "-l:libaws-c-mqtt.a",\n'
    '            "-l:libaws-c-event-stream.a",\n'
    '            "-l:libaws-c-s3.a",\n'
    '            "-l:libaws-c-auth.a",\n'
    '            "-l:libaws-c-http.a",\n'
    '            "-l:libaws-c-io.a",\n'
    '            "-l:libs2n.a",\n'
    '            "-l:libaws-c-compression.a",\n'
    '            "-l:libaws-c-cal.a",\n'
    '            "-l:libaws-c-sdkutils.a",\n'
    '            "-l:libaws-checksums.a",\n'
    '            "-l:libaws-c-common.a",\n'
    '            "-ldl -lm -lrt",\n'
    '            "-L/opt/%s-curl/lib" % arch,\n'
    '            "-L/opt/%s-ssl/lib" % arch,\n'
    '            "-L/opt/%s-zlib/lib" % arch,\n'
    '            "-L/opt/%s-aws/lib" % arch,\n'
    "        ] + select({\n"
    '            "//:dynamic_link": ["-lz", "-lssl", "-lcrypto", "-lcurl"],\n'
    '            "//conditions:default": [\n'
    '                "-l:libz.a",\n'
    '                "-l:libcurl.a",\n'
    '                "-l:libssl.a",\n'
    '                "-l:libcrypto.a",\n'
    "            ],\n"
    "        }),"
)
NEW_LINKOPTS = (
    "        linkopts = [\n"
    '            "-lpthread",\n'
    '            "-L/usr/local/lib64",\n'
    '            "-L/opt/%s-curl/lib" % arch,\n'
    '            "-L/opt/%s-ssl/lib" % arch,\n'
    '            "-L/opt/%s-zlib/lib" % arch,\n'
    '            "-L/opt/%s-aws/lib" % arch,\n'
    '            "-Wl,-rpath,/usr/local/lib64",\n'
    "        ] + select({\n"
    '            "//:dynamic_link": [\n'
    '                # Dynamic linking for all libraries\n'
    '                "-laws-cpp-sdk-s3-crt",\n'
    '                "-laws-cpp-sdk-core",\n'
    '                "-laws-crt-cpp",\n'
    '                "-laws-c-mqtt",\n'
    '                "-laws-c-event-stream",\n'
    '                "-laws-c-s3",\n'
    '                "-laws-c-auth",\n'
    '                "-laws-c-http",\n'
    '                "-laws-c-io",\n'
    '                "-ls2n",\n'
    '                "-laws-c-compression",\n'
    '                "-laws-c-cal",\n'
    '                "-laws-c-sdkutils",\n'
    '                "-laws-checksums",\n'
    '                "-laws-c-common",\n'
    '                "-lz",\n'
    '                "-lssl",\n'
    '                "-lcrypto",\n'
    '                "-lcurl",\n'
    '                "-ldl",\n'
    '                "-lm",\n'
    '                "-lrt",\n'
    '            ],\n'
    '            "//conditions:default": [\n'
    '                # Static linking (original)\n'
    '                "-l:libaws-cpp-sdk-s3-crt.a",\n'
    '                "-l:libaws-cpp-sdk-core.a",\n'
    '                "-l:libaws-crt-cpp.a",\n'
    '                "-l:libaws-c-mqtt.a",\n'
    '                "-l:libaws-c-event-stream.a",\n'
    '                "-l:libaws-c-s3.a",\n'
    '                "-l:libaws-c-auth.a",\n'
    '                "-l:libaws-c-http.a",\n'
    '                "-l:libaws-c-io.a",\n'
    '                "-l:libs2n.a",\n'
    '                "-l:libaws-c-compression.a",\n'
    '                "-l:libaws-c-cal.a",\n'
    '                "-l:libaws-c-sdkutils.a",\n'
    '                "-l:libaws-checksums.a",\n'
    '                "-l:libaws-c-common.a",\n'
    '                "-l:libz.a",\n'
    '                "-l:libcurl.a",\n'
    '                "-l:libssl.a",\n'
    '                "-l:libcrypto.a",\n'
    '                "-ldl",\n'
    '                "-lm",\n'
    '                "-lrt",\n'
    '            ],\n'
    "        }),"
)

if OLD_LINKOPTS in src:
    src = src.replace(OLD_LINKOPTS, NEW_LINKOPTS)
    with open(path, "w") as fh:
        fh.write(src)
    print("  aws.bzl patched OK")
else:
    print("  WARNING: could not find expected linkopts block in aws.bzl — dumping:")
    idx = src.find("linkopts")
    print(repr(src[idx:idx+400]) if idx >= 0 else "  (not found)")
PYEOF

# ---------------------------------------------------------------------------
# Step 6: Patch cpp/third_party/aws.BUILD (in-repo Bazel external file)
# ---------------------------------------------------------------------------
echo "==> Patching cpp/third_party/aws.BUILD (ppc64le config + alias)"

python3 - <<'PYEOF'
path = "cpp/third_party/aws.BUILD"
with open(path) as fh:
    src = fh.read()

changed = False

OLD_AARCH64_CFG = (
    'config_setting(\n'
    '    name = "target_aarch64",\n'
    '    constraint_values = [\n'
    '        "@platforms//cpu:aarch64",\n'
    '    ],\n'
    ')'
)
PPC_CFG = (
    '\n\nconfig_setting(\n'
    '    name = "target_ppc64le",\n'
    '    constraint_values = [\n'
    '        "@platforms//cpu:ppc",\n'
    '    ],\n'
    ')'
)
if "target_ppc64le" not in src:
    if OLD_AARCH64_CFG in src:
        src = src.replace(OLD_AARCH64_CFG, OLD_AARCH64_CFG + PPC_CFG)
        changed = True
    else:
        print("  WARNING: could not find target_aarch64 config_setting in aws.BUILD — dumping:")
        idx = src.find("target_aarch64")
        print(repr(src[max(0,idx-20):idx+200]) if idx >= 0 else "  (not found)")

if 'aws_library(name = "aws_ppc64le"' not in src:
    src = src.replace(
        'aws_library(name = "aws_x86_64", arch = "x86_64")',
        'aws_library(name = "aws_x86_64", arch = "x86_64")\n'
        'aws_library(name = "aws_ppc64le", arch = "ppc64le")'
    )
    changed = True

OLD_ALIAS_TAIL = (
    '        ":target_aarch64": ":aws_aarch",\n'
    '    }),\n'
    ')'
)
NEW_ALIAS_TAIL = (
    '        ":target_aarch64": ":aws_aarch",\n'
    '\t":target_ppc64le": ":aws_ppc64le",\n'
    '    }),\n'
    ')'
)
if '":target_ppc64le"' not in src:
    if OLD_ALIAS_TAIL in src:
        src = src.replace(OLD_ALIAS_TAIL, NEW_ALIAS_TAIL)
        changed = True
    else:
        print("  WARNING: could not find alias select block in aws.BUILD — dumping:")
        idx = src.find("alias(")
        print(repr(src[idx:idx+300]) if idx >= 0 else "  (not found)")

with open(path, "w") as fh:
    fh.write(src)
print("  aws.BUILD patched OK" if changed else "  aws.BUILD already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 7: Patch cpp/Makefile — build streamer + s3 targets (drop gcs, azure)
# The py/ packaging layer resolves the bazel-out symlink for libstreamer.so
# when assembling the s3 wheel; if libstreamer.so was not built in this Bazel
# output tree the symlink target is missing and setup.py raises FileNotFoundError.
# We therefore keep streamer:libstreamer.so in the build so the symlink is valid.
# ---------------------------------------------------------------------------
echo "==> Patching cpp/Makefile (streamer + s3 targets, drop gcs and azure)"

python3 - <<'PYEOF'
path = "cpp/Makefile"
with open(path) as fh:
    src = fh.read()

OLD_BUILD = (
    "build:\n"
    "\tbazel build streamer:libstreamer.so \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build s3:libstreamers3.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build gcs:libstreamergcs.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build azure:libstreamerazure.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}"'
)
# S3 wheel: build streamer first (py/ packaging needs the libstreamer.so
# symlink target to exist), then build libstreamers3.so; drop gcs and azure.
NEW_BUILD = (
    "build:\n"
    "\tbazel build streamer:libstreamer.so \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build s3:libstreamers3.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}"'
)

if "libstreamergcs.so" not in src:
    print("  cpp/Makefile already patched — skipping")
elif OLD_BUILD in src:
    src = src.replace(OLD_BUILD, NEW_BUILD)
    with open(path, "w") as fh:
        fh.write(src)
    print("  cpp/Makefile patched OK")
else:
    print("  WARNING: could not find expected build: block in cpp/Makefile — dumping:")
    idx = src.find("build:")
    print(repr(src[idx:idx+500]) if idx >= 0 else "  (not found)")
PYEOF

# ---------------------------------------------------------------------------
# Step 8: Patch py/Makefile — keep s3 wheel, drop gcs and azure
# ---------------------------------------------------------------------------
echo "==> Patching py/Makefile (s3 wheel only)"

python3 - <<'PYEOF'
path = "py/Makefile"
with open(path) as fh:
    lines = fh.readlines()

filtered = [
    line for line in lines
    if "runai_model_streamer_gcs" not in line
    and "runai_model_streamer_azure" not in line
]

if len(filtered) != len(lines):
    with open(path, "w") as fh:
        fh.writelines(filtered)
    removed = len(lines) - len(filtered)
    print(f"  py/Makefile patched OK (removed {removed} line(s))")
else:
    print("  py/Makefile already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 9: Build aws-sdk-cpp
# ---------------------------------------------------------------------------
echo "==> Building aws-sdk-cpp (this may take a while)"

AWS_SDK_DIR="$CURRENT_DIR/aws-sdk-cpp"
if [[ ! -d "$AWS_SDK_DIR" ]]; then
    git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp "$AWS_SDK_DIR"
fi

mkdir -p "$AWS_SDK_DIR/build"
cd "$AWS_SDK_DIR/build"

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ONLY="s3;core;s3-crt" \
    -DENABLE_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    ..

make -j"$(nproc)"
make install
ldconfig

cd "$CURRENT_DIR/$PACKAGE_DIR"

# ---------------------------------------------------------------------------
# Step 10: Patch the Bazel cache external/aws/BUILD.bazel
# cpp/third_party/aws.BUILD (patched above) is the *source* Bazel uses to
# materialise external/aws/BUILD.bazel in the cache.  If the cache copy already
# exists from a previous fetch it also needs to be patched directly so that the
# current build session picks up the changes without a full bazel clean --expunge.
# ---------------------------------------------------------------------------
echo "==> Patching Bazel cache external/aws/BUILD.bazel"

cd "$CURRENT_DIR/$PACKAGE_DIR/cpp"

BAZEL_OUTPUT_BASE="$(bazel info output_base 2>/dev/null)" \
    || { echo "ERROR: Could not determine Bazel output base — is Bazel installed?"; exit 1; }

AWS_CACHE_BUILD="$BAZEL_OUTPUT_BASE/external/aws/BUILD.bazel"

if [[ ! -f "$AWS_CACHE_BUILD" ]]; then
    echo "==> Fetching Bazel deps to materialise external/aws/BUILD.bazel ..."
    bazel fetch //... --config=ppc64le 2>/dev/null || true
    AWS_CACHE_BUILD="$(find "$BAZEL_OUTPUT_BASE/external" \
        -name BUILD.bazel -path "*/aws/BUILD.bazel" 2>/dev/null | head -1 || true)"
fi

if [[ -z "$AWS_CACHE_BUILD" || ! -f "$AWS_CACHE_BUILD" ]]; then
    echo "ERROR: Could not locate external/aws/BUILD.bazel under $BAZEL_OUTPUT_BASE"
    exit 1
fi

echo "==> Found cache file: $AWS_CACHE_BUILD"

python3 - "$AWS_CACHE_BUILD" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path) as fh:
    src = fh.read()

if "target_ppc64le" in src:
    print("  Bazel cache BUILD.bazel already patched — skipping")
    raise SystemExit(0)

changed = False

OLD_AARCH64_CFG = (
    'config_setting(\n'
    '    name = "target_aarch64",\n'
    '    constraint_values = [\n'
    '        "@platforms//cpu:aarch64",\n'
    '    ],\n'
    ')'
)
PPC_CFG = (
    '\n\nconfig_setting(\n'
    '    name = "target_ppc64le",\n'
    '    constraint_values = [\n'
    '        "@platforms//cpu:ppc",\n'
    '    ],\n'
    ')'
)
if OLD_AARCH64_CFG in src:
    src = src.replace(OLD_AARCH64_CFG, OLD_AARCH64_CFG + PPC_CFG)
    changed = True

if 'aws_library(name = "aws_ppc64le"' not in src:
    src = src.replace(
        'aws_library(name = "aws_x86_64", arch = "x86_64")',
        'aws_library(name = "aws_x86_64", arch = "x86_64")\n'
        'aws_library(name = "aws_ppc64le", arch = "ppc64le")'
    )
    changed = True

OLD_ALIAS_TAIL = (
    '        ":target_aarch64": ":aws_aarch",\n'
    '    }),\n'
    ')'
)
NEW_ALIAS_TAIL = (
    '        ":target_aarch64": ":aws_aarch",\n'
    '\t":target_ppc64le": ":aws_ppc64le",\n'
    '    }),\n'
    ')'
)
if OLD_ALIAS_TAIL in src:
    src = src.replace(OLD_ALIAS_TAIL, NEW_ALIAS_TAIL)
    changed = True

with open(path, "w") as fh:
    fh.write(src)
print("  Bazel cache BUILD.bazel patched OK" if changed else "  No changes made")
PYEOF

cd "$CURRENT_DIR/$PACKAGE_DIR"

# ---------------------------------------------------------------------------
# Step 11: Build
# ---------------------------------------------------------------------------
echo "==> Building runai-model-streamer-s3 wheel for ppc64le (version $PACKAGE_VERSION)"
export USE_SYSTEM_LIBS=1

if ! make build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR and install it.
# The core wheel must already be installed (libstreamers3.so is placed into
# the core package's lib directory by the s3 wheel's data_files).
find "$CURRENT_DIR/$PACKAGE_DIR/py" -name "runai_model_streamer_s3-*.whl" | while read -r whl; do
    cp "$whl" "$CURRENT_DIR/"
done

pip install "$CURRENT_DIR"/runai_model_streamer_s3-"${PACKAGE_VERSION}"-*.whl

# Run tests
if ! python3.12 - <<'PYEOF'
import sys
print(f"Python: {sys.version}")

# 1. S3 extension wheel import
print("\n[1] Importing runai_model_streamer_s3...")
import runai_model_streamer_s3
print(f"    runai_model_streamer_s3 import : OK")

# 2. Runtime dep: boto3
print("\n[2] Checking boto3...")
import boto3
print(f"    boto3 version       : {boto3.__version__}")

# 3. Credentials module
print("\n[3] Checking credentials module...")
from runai_model_streamer_s3.credentials.credentials import get_credentials
print(f"    credentials module  : OK")

# 4. Files module
print("\n[4] Checking files module...")
from runai_model_streamer_s3.files.files import glob, pull_files, list_files
print(f"    files module        : OK")

print("\n══════════════════════════════════════════════════════")
print("  All checks passed — runai-model-streamer-s3 OK")
print("══════════════════════════════════════════════════════")
PYEOF
then
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
