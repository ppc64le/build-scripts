#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.24.0
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI 10 (ppc64le)
# Language      : Python, C++, CUDA/HIP
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
# Clones vLLM, applies all ppc64le/ROCm patches, installs pre-built dependency
# wheels, and builds the final vLLM Python wheel.
#
# Usage:
#   ./build-vllm-rocm-ppc64le-rpm.sh [--vllm-version v0.24.0] [--workdir $HOME]
#
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"

# ─── System packages ──────────────────────────────────────────────────────────
# Install before argument parsing so --help works without side-effects only
# if sourced; the dnf step is intentionally unconditional for container use.
EPEL_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm"
if ! rpm -q epel-release &>/dev/null; then
    echo "==> Installing EPEL"
    dnf install -y "$EPEL_URL"
fi
echo "==> Installing system dependencies"
dnf install -y \
    git              \
    gcc-toolset-15   \
    python3.13       \
    python3.13-libs  \
    python3.13-devel

PYTHON_BIN="/usr/bin/python3.13"
GCC_TOOLSET_BIN="/opt/rh/gcc-toolset-15/root/usr/bin"
VLLM_REPO_URL="https://github.com/vllm-project/vllm.git"
VLLM_SRC_DIR="$PWD/vllm"
VLLM_VERSION="v0.24.0"
VENV_DIR="$PWD/vllm-venv"
ROCM_PATH="/opt/rocm"
TORCH_WHEEL_DIR="$PWD/torch-wheels"
EXTRA_WHEEL_DIR="$PWD/extra-wheels"
OUTPUT_DIR=""          # resolved to ${VLLM_SRC_DIR}/../vllm-wheels after arg parsing
SKIP_CLONE=0

die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  -p, --python PATH        Full path to Python executable.
                           If omitted, defaults to system python3 from PATH.

  --gcc-toolset-bin PATH   Path to GCC toolset bin directory.
                           Default: $GCC_TOOLSET_BIN

  --vllm-src PATH          vLLM source directory.
                           Default: ./vllm

  --vllm-version REF       vLLM Git tag, branch, or commit to build.
                           Default: $VLLM_VERSION

  --venv PATH              Virtual environment directory.
                           Default: ./vllm-venv

  --rocm-path PATH         Path to the system-wide ROCm installation.
                           Default: /opt/rocm

  --torch-wheel-dir PATH   Directory containing torch, torchvision, and torchaudio wheels.
                           Default: ./torch-wheels

  --extra-wheel-dir PATH   Directory containing extra wheels such as Triton and Run:ai model streamer.
                           Default: ./extra-wheels

  --output-dir PATH        Directory to copy the final vLLM wheel into.
                           Default: <vllm-src>/../vllm-wheels

  --skip-clone             Do not clone vLLM. Require --vllm-src to already exist.

  -h, --help               Show this help message.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--python)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                PYTHON_BIN="$2"
                shift 2
                ;;
            --gcc-toolset-bin)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                GCC_TOOLSET_BIN="$2"
                shift 2
                ;;
            --vllm-src)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                VLLM_SRC_DIR="$2"
                shift 2
                ;;
            --vllm-version)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                VLLM_VERSION="$2"
                shift 2
                ;;
            --venv)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                VENV_DIR="$2"
                shift 2
                ;;
            --rocm-path)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                ROCM_PATH="$2"
                shift 2
                ;;
            --torch-wheel-dir)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                TORCH_WHEEL_DIR="$2"
                shift 2
                ;;
            --extra-wheel-dir)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                EXTRA_WHEEL_DIR="$2"
                shift 2
                ;;
            --output-dir)
                [[ $# -ge 2 ]] || die "Missing value for $1"
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --skip-clone)
                SKIP_CLONE=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

resolve_python() {
    if [[ -n "$PYTHON_BIN" ]]; then
        [[ "$PYTHON_BIN" == /* ]] || die "--python must be an absolute path to an executable"
        [[ -x "$PYTHON_BIN" ]] || die "Python executable not found or not executable: $PYTHON_BIN"
        # Do NOT use realpath here — it follows symlinks to the underlying binary
        # which may be a different Python version (e.g. /usr/bin/python3.13 on
        # UBI 10 can be a symlink whose target resolves to the system 3.12 binary).
        # We trust the path as given and verify the version explicitly instead.
    else
        PYTHON_BIN="$(command -v python3)" || die "python3 not found in PATH. Use --python /path/to/python."
        echo "No --python provided. Defaulting to system python3."
    fi

    "$PYTHON_BIN" -c 'import sys' || die "Selected Python is not runnable"

    local actual_version
    actual_version="$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
    local expected_version
    expected_version="$(basename "$PYTHON_BIN" | grep -oP '\d+\.\d+' || true)"
    if [[ -n "$expected_version" && "$actual_version" != "$expected_version" ]]; then
        die "Python version mismatch: $PYTHON_BIN reports version $actual_version but $expected_version was expected based on the executable name. Check that the correct Python is installed and /usr/bin/python3.13 is not a symlink to a different version."
    fi
}

print_python_info() {
    local version
    version="$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')"

    echo "Using Python executable: $PYTHON_BIN"
    echo "Using Python version:    $version"
}

setup_gcc_toolset() {
    [[ -d "$GCC_TOOLSET_BIN" ]] || die "GCC toolset bin directory not found: $GCC_TOOLSET_BIN"

    export PATH="$GCC_TOOLSET_BIN:$PATH"

    command -v gcc >/dev/null || die "gcc not found after adding $GCC_TOOLSET_BIN to PATH"
    command -v g++ >/dev/null || die "g++ not found after adding $GCC_TOOLSET_BIN to PATH"

    echo "Using gcc: $(command -v gcc)"
    echo "GCC version: $(gcc -dumpfullversion -dumpversion)"
}

clone_or_check_vllm() {
    if [[ -d "$VLLM_SRC_DIR/.git" ]]; then
        echo "Using existing vLLM source directory: $VLLM_SRC_DIR"

        cd "$VLLM_SRC_DIR"

        local remote_url
        remote_url="$(git remote get-url origin)"

        if [[ "$remote_url" != "$VLLM_REPO_URL" ]]; then
            die "Existing repository origin does not match expected vLLM repo.
Expected: $VLLM_REPO_URL
Found:    $remote_url"
        fi

        return
    fi

    if [[ "$SKIP_CLONE" -eq 1 ]]; then
        die "--skip-clone was set, but vLLM source directory is missing or not a git repo: $VLLM_SRC_DIR"
    fi

    [[ ! -e "$VLLM_SRC_DIR" ]] || die "vLLM source path exists but is not a git repo: $VLLM_SRC_DIR"

    command -v git >/dev/null || die "git not found in PATH"

    echo "Cloning vLLM into: $VLLM_SRC_DIR"
    git clone "$VLLM_REPO_URL" "$VLLM_SRC_DIR"
}

checkout_vllm_version() {
    echo "Preparing vLLM source..."

    cd "$VLLM_SRC_DIR"

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
        || die "$VLLM_SRC_DIR is not a git repository"

    echo "Fetching latest tags/references..."
    git fetch --tags origin

    git rev-parse --verify "$VLLM_VERSION^{commit}" >/dev/null 2>&1 \
        || die "Git reference '$VLLM_VERSION' does not exist."

    echo "Checking out $VLLM_VERSION..."
    git checkout "$VLLM_VERSION"

    echo "Current vLLM commit:"
    git --no-pager log -1 --oneline
}

create_and_activate_venv() {
    if [[ ! -d "$VENV_DIR" ]]; then
        echo "Creating virtual environment: $VENV_DIR"
        "$PYTHON_BIN" -m venv "$VENV_DIR"
    else
        echo "Using existing virtual environment: $VENV_DIR"
    fi

    [[ -f "$VENV_DIR/bin/activate" ]] || die "venv activate script not found: $VENV_DIR/bin/activate"

    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"

    export VIRTUAL_ENV="$VENV_DIR"
    export PATH="$VIRTUAL_ENV/bin:$PATH"

    echo "Active Python: $(command -v python)"
    echo "Active pip:    $(command -v pip)"

    python -m pip install -U pip
}

find_single_package_file() {
    local dir="$1"
    local pattern="$2"
    local label="$3"

    mapfile -t matches < <(find "$dir" -maxdepth 1 -type f -name "$pattern" | sort)

    if [[ "${#matches[@]}" -eq 0 ]]; then
        die "Could not find required package: $label
Directory: $dir
Pattern:   $pattern"
    fi

    if [[ "${#matches[@]}" -gt 1 ]]; then
        printf 'ERROR: Found multiple matches for %s:\n' "$label" >&2
        printf '  %s\n' "${matches[@]}" >&2
        die "Please keep only one matching file or use a cleaner wheel directory."
    fi

    echo "${matches[0]}"
}

install_torch_wheels() {
    [[ -d "$TORCH_WHEEL_DIR" ]] || die "Torch wheel directory not found: $TORCH_WHEEL_DIR"

    local torch_wheel
    local torchvision_wheel
    local torchaudio_wheel

    torch_wheel="$(find_single_package_file "$TORCH_WHEEL_DIR" 'torch-*.whl' 'torch')"
    torchvision_wheel="$(find_single_package_file "$TORCH_WHEEL_DIR" 'torchvision-*.whl' 'torchvision')"
    torchaudio_wheel="$(find_single_package_file "$TORCH_WHEEL_DIR" 'torchaudio-*.whl' 'torchaudio')"

    echo "Installing torch-family packages in required order:"
    echo "  1. $torch_wheel"
    echo "  2. $torchvision_wheel"
    echo "  3. $torchaudio_wheel"

    python -m pip install "$torch_wheel"
    python -m pip install "$torchvision_wheel"
    python -m pip install "$torchaudio_wheel"

    echo "Installed torch-family packages:"
    python -m pip list | grep -E 'torch|torchvision|torchaudio' || true
}

run_use_existing_torch_patch() {
    cd "$VLLM_SRC_DIR"

    [[ -f "use_existing_torch.py" ]] || die "Missing vLLM patch script: $VLLM_SRC_DIR/use_existing_torch.py"

    echo "Running vLLM use_existing_torch.py patch..."
    python use_existing_torch.py
}

patch_rocm_build_requirements() {
    cd "$VLLM_SRC_DIR"

    local req_file="requirements/build/rocm.txt"

    [[ -f "$req_file" ]] || die "Missing ROCm build requirements file: $VLLM_SRC_DIR/$req_file"

    if grep -q '^triton==3\.6\.0$' "$req_file"; then
        echo "Patching $req_file: triton==3.6.0 -> triton>=3.6.0"
        sed -i 's/^triton==3\.6\.0$/triton>=3.6.0/' "$req_file"
    elif grep -q '^triton>=3\.6\.0$' "$req_file"; then
        echo "$req_file already patched for triton>=3.6.0"
    else
        echo "Current triton requirement in $req_file:"
        grep -n '^triton' "$req_file" || true
        die "Could not find expected triton==3.6.0 line to patch."
    fi

    # Remove the PyPI amdsmi pin. It installs a version incompatible with the
    # system libamd_smi.so. The correct matching amdsmi is installed separately
    # from $ROCM_PATH/share/amd_smi by install_amdsmi().
    if grep -q '^amdsmi' "$req_file"; then
        echo "Patching $req_file: removing amdsmi line (installed from system ROCm instead)"
        sed -i '/^amdsmi/d' "$req_file"
    else
        echo "$req_file already has no amdsmi line."
    fi
}

patch_setup_py_hip_flags() {
    cd "$VLLM_SRC_DIR"

    local setup_file="setup.py"
    [[ -f "$setup_file" ]] || die "Missing setup.py: $VLLM_SRC_DIR/setup.py"

    local rocm_bitcode_dir="$ROCM_PATH/lib/llvm/amdgcn/bitcode"
    [[ -d "$rocm_bitcode_dir" ]] || die "ROCm bitcode directory not found: $rocm_bitcode_dir"

    echo "Patching setup.py CMAKE_HIP_FLAGS with ROCm bitcode path:"
    echo "  $rocm_bitcode_dir"

    python - <<PY
from pathlib import Path

setup_file = Path("setup.py")
text = setup_file.read_text()

hip_flag = '            "-DCMAKE_HIP_FLAGS=--rocm-device-lib-path=${rocm_bitcode_dir}/",\\n'

target = '''cmake_args = [
            "-DCMAKE_BUILD_TYPE={}".format(cfg),
            "-DVLLM_TARGET_DEVICE={}".format(VLLM_TARGET_DEVICE),
        ]'''

replacement = '''cmake_args = [
            "-DCMAKE_BUILD_TYPE={}".format(cfg),
            "-DVLLM_TARGET_DEVICE={}".format(VLLM_TARGET_DEVICE),
''' + hip_flag + '''        ]'''

if hip_flag.strip() in text:
    print("setup.py already contains desired CMAKE_HIP_FLAGS patch.")
elif target in text:
    text = text.replace(target, replacement, 1)
    setup_file.write_text(text)
    print("setup.py patched successfully.")
else:
    raise SystemExit("Could not find the expected first cmake_args block in setup.py.")
PY
}

patch_setup_py_runai_extra() {
    cd "$VLLM_SRC_DIR"

    local setup_file="setup.py"
    [[ -f "$setup_file" ]] || die "Missing setup.py: $VLLM_SRC_DIR/setup.py"

    echo "Patching setup.py runai extra dependency..."

    python - <<'PY'
from pathlib import Path

p = Path("setup.py")
text = p.read_text()

old = '"runai": ["runai-model-streamer[s3,gcs,azure] >= 0.15.7"],'
new = '"runai": ["runai-model-streamer[s3] >= 0.15.7"],'

if new in text:
    print("setup.py runai extra already patched.")
elif old in text:
    text = text.replace(old, new, 1)
    p.write_text(text)
    print("setup.py runai extra patched successfully.")
else:
    raise SystemExit("Could not find expected runai extra dependency line in setup.py.")
PY
}

apply_vllm_patches() {
    run_use_existing_torch_patch
    patch_rocm_build_requirements
    patch_setup_py_hip_flags
    patch_setup_py_runai_extra
}

install_triton_wheel() {
    [[ -d "$EXTRA_WHEEL_DIR" ]] || die "Extra wheel directory not found: $EXTRA_WHEEL_DIR"

    local triton_wheel
    triton_wheel="$(find_single_package_file "$EXTRA_WHEEL_DIR" 'triton-*.whl' 'triton')"

    echo "Installing Triton wheel:"
    echo "  $triton_wheel"

    python -m pip install "$triton_wheel"

    echo "Installed Triton package:"
    python -m pip list | grep -E '^triton[[:space:]]+' || true
}

install_runai_model_streamer_wheel() {
    [[ -d "$EXTRA_WHEEL_DIR" ]] || die "Extra wheel directory not found: $EXTRA_WHEEL_DIR"

    local runai_base_wheel runai_s3_wheel
    runai_base_wheel="$(find_single_package_file "$EXTRA_WHEEL_DIR" 'runai_model_streamer-*.whl' 'runai-model-streamer')"
    runai_s3_wheel="$(find_single_package_file "$EXTRA_WHEEL_DIR" 'runai_model_streamer_s3-*.whl' 'runai-model-streamer-s3')"

    echo "Installing Run:ai model streamer wheels:"
    echo "  $runai_base_wheel"
    echo "  $runai_s3_wheel"

    # Base wheel must be installed first — the s3 wheel depends on it.
    python -m pip install "$runai_base_wheel"
    python -m pip install "$runai_s3_wheel"

    echo "Installed Run:ai packages:"
    python -m pip list | grep -E 'runai|model-streamer' || true
}

install_z3_and_tilelang_wheels() {
    [[ -d "$EXTRA_WHEEL_DIR" ]] || die "Extra wheel directory not found: $EXTRA_WHEEL_DIR"
    local z3_wheel
    z3_wheel="$(find_single_package_file "$EXTRA_WHEEL_DIR" 'z3_solver-*.whl' 'z3-solver')"
    local tilelang_wheel
    tilelang_wheel="$(find_single_package_file "$EXTRA_WHEEL_DIR" 'tilelang-*.whl' 'tilelang')"

    echo "Installing z3-solver wheel:"
    echo "  $z3_wheel"

    python -m pip install "$z3_wheel"

    echo "Installing tilelang wheel:"
    echo "  $tilelang_wheel"

    # tilelang is installed with --no-build-isolation so that pip reuses the
    # already-installed torch in this venv rather than downloading a fresh copy.
    # With --no-build-isolation pip does not create an isolated build environment,
    # so any build-time deps that tilelang's transitive dependencies (e.g.
    # apache-tvm-ffi) require must already be present in the venv.
    # apache-tvm-ffi build-system.requires (from its pyproject.toml):
    #   scikit-build-core>=0.10.0, cython>=3.2.8, setuptools-scm
    python -m pip install cmake ninja "scikit-build-core[pyproject]>=0.10.0" "cython>=3.2.8" setuptools-scm
    python -m pip install "$tilelang_wheel" --no-build-isolation

    echo "Installed z3-solver and tilelang packages:"
    python -m pip list | grep -E 'z3' || true
    python -m pip list | grep -E 'tilelang' || true
}

install_opencv_and_grpcio() {
    echo "Installing opencv-python-headless and grpcio..."

    python -m pip install \
        --no-cache \
        --prefer-binary \
        opencv-python-headless==4.13.0.92 \
        grpcio \
        --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
}

install_extra_dependencies() {
    install_triton_wheel
    install_runai_model_streamer_wheel
    install_opencv_and_grpcio
    install_z3_and_tilelang_wheels
}

setup_rocm_build_env() {
    [[ -d "$ROCM_PATH" ]] || die "ROCm installation not found: $ROCM_PATH"
    [[ -d "$ROCM_PATH/lib" ]] || die "ROCm lib directory not found: $ROCM_PATH/lib"

    export ROCM_PATH
    export CMAKE_PREFIX_PATH="$ROCM_PATH:${CMAKE_PREFIX_PATH:-}"
    export PATH="$ROCM_PATH/bin:$PATH"
    export LD_LIBRARY_PATH="$ROCM_PATH/lib:${LD_LIBRARY_PATH:-}"

    echo "ROCm build environment:"
    echo "  ROCM_PATH=$ROCM_PATH"
    echo "  CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"
    echo "  LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
}

install_amdsmi() {
    local amdsmi_source_dir="$ROCM_PATH/share/amd_smi"

    [[ -d "$amdsmi_source_dir" ]] \
        || die "AMDSMI source directory not found: $amdsmi_source_dir"

    local tmpdir
    tmpdir="$(mktemp -d)" || die "Failed to create temporary directory for AMDSMI"

    echo "Installing matching AMDSMI Python bindings..."
    echo "  Source:    $amdsmi_source_dir"
    echo "  Temporary: $tmpdir"

    cp -a "$amdsmi_source_dir/." "$tmpdir/" \
        || { rm -rf "$tmpdir"; die "Failed to copy AMDSMI source into temporary directory"; }

    python -m pip install \
        --force-reinstall \
        --no-deps \
        "$tmpdir" \
        || { rm -rf "$tmpdir"; die "Failed to install matching AMDSMI Python bindings"; }

    rm -rf "$tmpdir"

    local installed_location
    installed_location="$(
        python - <<'PY'
import importlib.util

spec = importlib.util.find_spec("amdsmi")
if spec is None:
    raise SystemExit("amdsmi is not importable")

print(spec.origin)
PY
    )"

    echo "Installed AMDSMI module: $installed_location"

    case "$installed_location" in
        "$VENV_DIR"/*)
            ;;
        *)
            die "AMDSMI was installed outside the virtual environment: $installed_location"
            ;;
    esac
}

build_vllm_wheel() {
    cd "$VLLM_SRC_DIR"

    setup_rocm_build_env

    [[ -f "requirements/build/rocm.txt" ]] \
        || die "Missing requirements/build/rocm.txt"

    echo "Installing vLLM ROCm build requirements..."
    python -m pip install -r requirements/build/rocm.txt

    install_amdsmi

    echo "Building vLLM ROCm wheel..."
    VLLM_TARGET_DEVICE="rocm" python setup.py bdist_wheel --universal

    echo "Build complete. Wheel files:"
    ls -lh dist/*.whl

    mkdir -p "$OUTPUT_DIR"
    find dist -maxdepth 1 -name "vllm-*.whl" | while read -r whl; do
        cp "$whl" "$OUTPUT_DIR/"
    done
    echo "vLLM wheel copied to $OUTPUT_DIR"
}

main() {
    parse_args "$@"
    # Resolve OUTPUT_DIR now that VLLM_SRC_DIR is final
    OUTPUT_DIR="${OUTPUT_DIR:-$(dirname "$VLLM_SRC_DIR")/vllm-wheels}"
    resolve_python
    print_python_info

    setup_gcc_toolset
    clone_or_check_vllm
    checkout_vllm_version
    create_and_activate_venv
    install_torch_wheels
    apply_vllm_patches
    install_extra_dependencies
    build_vllm_wheel
}

main "$@"

