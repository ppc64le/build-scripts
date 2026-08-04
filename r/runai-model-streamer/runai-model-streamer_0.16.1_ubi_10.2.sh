#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : runai-model-streamer
# Version       : 0.16.1
# Source repo   : https://github.com/run-ai/runai-model-streamer
# Tested on     : UBI 10 (ppc64le)
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
# ----------------------------------------------------------------------------
#
# Clones runai-model-streamer, applies all ppc64le patches, and builds the two
# wheel files:
#   runai_model_streamer-<version>-py3-none-manylinux2014_ppc64le.whl
#   runai_model_streamer_s3-<version>-py3-none-manylinux2014_ppc64le.whl
#
# Bazel is not available as a pre-built binary for ppc64le. This script
# bootstraps Bazel 7.6.1 from the official source distribution (dist.zip)
# using only the JDK and GCC Toolset 15. The resulting binary is installed
# to /usr/local/bin/bazel. Pass --skip-bazel-build if it is already present.
#
# Usage:
#   ./runai-model-streamer_0.16.1_ubi_10.2.sh [--version 0.16.1] [--workdir $HOME]
#                                                [--output-dir $HOME/vllm-wheels]
#                                                [--skip-bazel-build]
#                                                [--skip-aws-build] [--bazel-clean]
#
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"

# ─── Defaults ─────────────────────────────────────────────────────────────────
PACKAGE_VERSION="0.16.1"
BAZEL_VERSION="7.6.1"
WORK_DIR="${HOME}"
OUTPUT_DIR=""          # resolved to ${WORK_DIR}/vllm-wheels after arg parsing
SKIP_BAZEL_BUILD=0
SKIP_AWS_BUILD=0
BAZEL_CLEAN=0

# ─── Helpers ──────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  --version VERSION       runai-model-streamer version tag (default: $PACKAGE_VERSION)
  --bazel-version VERSION Bazel version to bootstrap (default: $BAZEL_VERSION)
  --workdir DIR           parent directory for the clone (default: $WORK_DIR)
  --output-dir DIR        directory to copy the built wheels into (default: <workdir>/vllm-wheels)
  --skip-bazel-build      skip Bazel bootstrap (requires bazel already on PATH)
  --skip-aws-build        skip cloning/building aws-sdk-cpp (if already installed)
  --bazel-clean           run 'bazel clean --expunge' before the main build
  -h, --help              show this help and exit
EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)          PACKAGE_VERSION="$2"; shift 2 ;;
        --bazel-version)    BAZEL_VERSION="$2";   shift 2 ;;
        --workdir)          WORK_DIR="$2";         shift 2 ;;
        --output-dir)       OUTPUT_DIR="$2";        shift 2 ;;
        --skip-bazel-build) SKIP_BAZEL_BUILD=1;    shift   ;;
        --skip-aws-build)   SKIP_AWS_BUILD=1;      shift   ;;
        --bazel-clean)      BAZEL_CLEAN=1;         shift   ;;
        -h|--help)          usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

# Resolve OUTPUT_DIR now that WORK_DIR is final
OUTPUT_DIR="${OUTPUT_DIR:-${WORK_DIR}/vllm-wheels}"

# ─── System packages ──────────────────────────────────────────────────────────
info "Installing system dependencies"
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y \
    git                   \
    gcc-toolset-15        \
    gcc-c++               \
    cmake                 \
    ninja-build           \
    java-21-openjdk-devel \
    libcurl-devel         \
    openssl-devel         \
    libuuid-devel         \
    unzip                 \
    zip                   \
    patch                 \
    python3.13            \
    python3.13-devel

REPO_DIR="$WORK_DIR/runai-model-streamer"

# ─── Environment setup ────────────────────────────────────────────────────────
info "Configuring environment"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms200m"
export PATH="$JAVA_HOME/bin:$PATH"
export PACKAGE_VERSION

# Enable GCC Toolset 15.
# Some installations provide an 'enable' script; others only have the bin dir.
GCC_TOOLSET_BIN="/opt/rh/gcc-toolset-15/root/usr/bin"
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    # shellcheck disable=SC1091
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d "$GCC_TOOLSET_BIN" ]]; then
    export PATH="$GCC_TOOLSET_BIN:$PATH"
else
    die "/opt/rh/gcc-toolset-15 not found — install gcc-toolset-15"
fi

# ─── Step 0: Bootstrap Bazel from source ──────────────────────────────────────
# No pre-built Bazel binary exists for ppc64le. We bootstrap from the official
# source distribution (dist.zip), which only requires a JDK and a C++ compiler.
# The compiled binary is installed to /usr/local/bin/bazel.
if [[ "$SKIP_BAZEL_BUILD" -eq 1 ]]; then
    command -v bazel &>/dev/null \
        || die "--skip-bazel-build set but bazel not found on PATH"
    info "Skipping Bazel bootstrap — using $(command -v bazel) ($(bazel version 2>/dev/null | head -1))"
else
    BAZEL_DIST_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_DIST_ZIP="$WORK_DIR/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_BUILD_DIR="$WORK_DIR/bazel-${BAZEL_VERSION}-src"

    if [[ -x /usr/local/bin/bazel ]]; then
        INSTALLED_VER="$(/usr/local/bin/bazel version 2>/dev/null | awk '/Build label/{print $NF}')"
        if [[ "$INSTALLED_VER" == "$BAZEL_VERSION" ]]; then
            info "Bazel $BAZEL_VERSION already installed at /usr/local/bin/bazel — skipping bootstrap"
            SKIP_BAZEL_BUILD=1
        fi
    fi

    if [[ "$SKIP_BAZEL_BUILD" -eq 0 ]]; then
        info "Downloading Bazel $BAZEL_VERSION source distribution"
        [[ -f "$BAZEL_DIST_ZIP" ]] \
            || curl -fL "$BAZEL_DIST_URL" -o "$BAZEL_DIST_ZIP"

        info "Extracting Bazel source distribution"
        if [[ ! -d "$BAZEL_BUILD_DIR" ]]; then
            mkdir -p "$BAZEL_BUILD_DIR"
            unzip -q "$BAZEL_DIST_ZIP" -d "$BAZEL_BUILD_DIR"
        fi

        info "Bootstrapping Bazel (this may take 10–20 minutes)"
        cd "$BAZEL_BUILD_DIR"
        # Bazel 7.6.1 sources are not compatible with GCC 15 (missing <cstdint>
        # transitive includes). RHEL 10 ships GCC 14 as the system compiler
        # (/usr/bin/gcc from gcc-c++), which builds Bazel cleanly. We
        # temporarily shadow the toolset-15 gcc/g++ with the system versions
        # just for this bootstrap, then restore PATH afterwards.
        #
        # EXTRA_BAZEL_ARGS is forwarded to the inner 'bazel build' call:
        #   --tool_java_runtime_version=local_jdk  prevents the bootstrap from
        #     downloading a hermetic JDK; it uses the system JDK instead.
        #   --jobs=N  caps parallel actions so the bootstrap does not exhaust
        #     the system thread limit (EAGAIN from pthread_create). Each
        #     parallel JVM action needs ~10 threads; 4 jobs keeps peak thread
        #     count well within default container limits.
        #
        # ulimit -u raises the per-user max processes/threads ceiling for this
        # shell; the kernel default in many container runtimes is low (1024).
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
        info "Bazel installed: $(bazel version 2>/dev/null | head -1)"
        cd "$WORK_DIR"
    fi
fi

# ─── Step 1: Clone the repository and checkout the requested version ──────────
info "Cloning runai-model-streamer into $REPO_DIR"
if [[ -d "$REPO_DIR" ]]; then
    info "Directory already exists — skipping clone"
else
    git clone https://github.com/run-ai/runai-model-streamer "$REPO_DIR"
fi

cd "$REPO_DIR"

# Checkout the tag that matches PACKAGE_VERSION.
# The repo uses tags like "v0.15.7"; fall back to bare "0.15.7" if not found.
info "Checking out version $PACKAGE_VERSION"
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    die "No git tag found for version '$PACKAGE_VERSION' (tried v${PACKAGE_VERSION} and ${PACKAGE_VERSION})"
fi

info "HEAD commit: $(git log --oneline -1)"

# ─── Step 2: Patch top-level Makefile ─────────────────────────────────────────
# The upstream Makefile uses TABS for recipe indentation.
# "build:" has a trailing space: "build: "
info "Patching Makefile (ppc64le arch + build target)"

python3 - <<'PYEOF'
path = "Makefile"
with open(path) as fh:
    src = fh.read()

changed = False

# 1) Insert PPC64LE_ARCH variable after AARCH64_ARCH line
if "PPC64LE_ARCH" not in src:
    src = src.replace(
        "AARCH64_ARCH := aarch64",
        "AARCH64_ARCH := aarch64\nPPC64LE_ARCH := ppc64le"
    )
    changed = True

# 2) Insert build_ppc64le target after build_aarch64 block (tab-indented)
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

# 3) Replace the build: recipe — note the trailing space after "build:"
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

# ─── Step 3: Patch cpp/.bazelrc ───────────────────────────────────────────────
info "Patching cpp/.bazelrc (ppc64le platform suffix)"

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

# ─── Step 4: Patch cpp/cc/freeres/freeres.cc ──────────────────────────────────
# Removes the hidden visibility attribute that causes link errors on ppc64le.
info "Patching cpp/cc/freeres/freeres.cc (__freeres visibility)"

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

# ─── Step 5: Patch cpp/third_party/aws.bzl ────────────────────────────────────
# Replaces the original static-only linkopts with a dynamic/static select()
# block that also adds the /usr/local/lib64 search path for the system-installed
# aws-sdk-cpp.  Uses exact literal replacement against the known upstream content.
info "Patching cpp/third_party/aws.bzl (linkopts)"

python3 - <<'PYEOF'
path = "cpp/third_party/aws.bzl"
with open(path) as fh:
    src = fh.read()

if '"-L/usr/local/lib64"' in src:
    print("  aws.bzl already patched — skipping")
    raise SystemExit(0)

# Exact upstream linkopts block (no -L lines, simple static list + small select)
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

# ─── Step 6: Patch cpp/third_party/aws.BUILD (in-repo Bazel external file) ────
# This file is the template Bazel uses to populate the external/aws/ package.
# It needs the ppc64le config_setting, library declaration, and alias entry.
info "Patching cpp/third_party/aws.BUILD (ppc64le config + alias)"

python3 - <<'PYEOF'
path = "cpp/third_party/aws.BUILD"
with open(path) as fh:
    src = fh.read()

changed = False

# 1) Add ppc64le config_setting after the target_aarch64 block
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

# 2) Add aws_ppc64le library declaration after aws_x86_64
if 'aws_library(name = "aws_ppc64le"' not in src:
    src = src.replace(
        'aws_library(name = "aws_x86_64", arch = "x86_64")',
        'aws_library(name = "aws_x86_64", arch = "x86_64")\n'
        'aws_library(name = "aws_ppc64le", arch = "ppc64le")'
    )
    changed = True

# 3) Add ppc64le entry in the alias select() block
# The diff shows the entry uses a tab before ":target_ppc64le" (mixed indent)
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

# ─── Step 7: Patch cpp/Makefile (drop gcs and azure build targets) ────────────
# Uses TABS for recipe indentation.
info "Patching cpp/Makefile (build only streamer + s3, drop gcs/azure)"

python3 - <<'PYEOF'
path = "cpp/Makefile"
with open(path) as fh:
    src = fh.read()

# Exact tab-indented upstream 4-target build: block
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
NEW_BUILD = (
    "build:\n"
    "\tbazel build streamer:libstreamer.so \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build s3:libstreamers3.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}"'
)

# Check for gcs target — only present in the unpatched file
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

# ─── Step 8: Patch py/Makefile (remove gcs and azure references) ──────────────
info "Patching py/Makefile (removing gcs and azure references)"

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

# ─── Step 9: Build aws-sdk-cpp (optional) ─────────────────────────────────────
if [[ "$SKIP_AWS_BUILD" -eq 0 ]]; then
    info "Building aws-sdk-cpp (this may take a while)"

    AWS_SDK_DIR="$WORK_DIR/aws-sdk-cpp"
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

    cd "$REPO_DIR"
else
    info "Skipping aws-sdk-cpp build (--skip-aws-build)"
fi

# ─── Step 10: Set up Python venv ──────────────────────────────────────────────
info "Setting up Python venv at $REPO_DIR/runai"
if [[ ! -d "$REPO_DIR/runai" ]]; then
    python3.13 -m venv "$REPO_DIR/runai"
fi
# shellcheck disable=SC1091
source "$REPO_DIR/runai/bin/activate"
pip install --upgrade pip setuptools

# ─── Step 11: Patch the Bazel cache external/aws/BUILD.bazel ─────────────────
# cpp/third_party/aws.BUILD (patched above) is the *source* Bazel uses to
# materialise external/aws/BUILD.bazel in the cache.  If the cache copy already
# exists from a previous fetch it also needs to be patched directly so that the
# current build session picks up the changes without a full bazel clean --expunge.
info "Patching Bazel cache external/aws/BUILD.bazel"

cd "$REPO_DIR/cpp"

BAZEL_OUTPUT_BASE="$(bazel info output_base 2>/dev/null)" \
    || die "Could not determine Bazel output base — is Bazel installed?"

AWS_CACHE_BUILD="$BAZEL_OUTPUT_BASE/external/aws/BUILD.bazel"

if [[ ! -f "$AWS_CACHE_BUILD" ]]; then
    info "Fetching Bazel deps to materialise external/aws/BUILD.bazel ..."
    bazel fetch //... --config=ppc64le 2>/dev/null || true
    # The fetch may place it under a different hash-named subdir; search for it
    AWS_CACHE_BUILD="$(find "$BAZEL_OUTPUT_BASE/external" \
        -name BUILD.bazel -path "*/aws/BUILD.bazel" 2>/dev/null | head -1 || true)"
fi

if [[ -z "$AWS_CACHE_BUILD" || ! -f "$AWS_CACHE_BUILD" ]]; then
    die "Could not locate external/aws/BUILD.bazel under $BAZEL_OUTPUT_BASE"
fi

info "Found cache file: $AWS_CACHE_BUILD"

python3 - "$AWS_CACHE_BUILD" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path) as fh:
    src = fh.read()

if "target_ppc64le" in src:
    print("  Bazel cache BUILD.bazel already patched — skipping")
    raise SystemExit(0)

changed = False

# 1) Add ppc64le config_setting after target_aarch64 block
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

# 2) Add aws_ppc64le library declaration after aws_x86_64
if 'aws_library(name = "aws_ppc64le"' not in src:
    src = src.replace(
        'aws_library(name = "aws_x86_64", arch = "x86_64")',
        'aws_library(name = "aws_x86_64", arch = "x86_64")\n'
        'aws_library(name = "aws_ppc64le", arch = "ppc64le")'
    )
    changed = True

# 3) Add ppc64le entry in the alias select() block
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

cd "$REPO_DIR"

# ─── Step 12: Optional bazel clean ────────────────────────────────────────────
if [[ "$BAZEL_CLEAN" -eq 1 ]]; then
    info "Running bazel clean --expunge"
    (cd "$REPO_DIR/cpp" && bazel clean --expunge)
fi

# ─── Step 13: Build ───────────────────────────────────────────────────────────
info "Building runai-model-streamer for ppc64le (version $PACKAGE_VERSION)"
export USE_SYSTEM_LIBS=1
export PACKAGE_VERSION

make build

# ─── Step 14: Copy wheels to staging area and report ─────────────────────────
info "Build complete. Wheels:"
find "$REPO_DIR/py" -name "*.whl" | sort | while read -r whl; do
    echo "  $whl"
done

mkdir -p "$OUTPUT_DIR"
find "$REPO_DIR/py" -name "*.whl" | while read -r whl; do
    cp "$whl" "$OUTPUT_DIR/"
done
info "Runai wheels copied to $OUTPUT_DIR"

