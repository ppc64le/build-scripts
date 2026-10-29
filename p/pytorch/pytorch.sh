#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pytorch
# Version       : v2.6.0
# Source repo   : https://github.com/pytorch/pytorch
# Tested on     : UBI:9.6
# Language      : C++, Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pytorch"
PACKAGE_VERSION="${1:-v2.6.0}"
PACKAGE_URL="https://github.com/pytorch/pytorch"

# =============================================================================
# Artifact Declaration (Tier 2 - depends on openblas, abseil-cpp)
# =============================================================================
PROVIDES_ARTIFACT="pytorch"
BUILD_DEPS="openblas abseil-cpp:20240116.2 libprotobuf:v26.1 numpy:v2.2.5"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for the build
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make cmake ninja-build \
    python3-devel python3-pip \
    openssl-devel bzip2-devel libffi-devel libevent-devel \
    zlib-devel xz patch wget pkg-config libtool \
    gcc-toolset-13 gcc-toolset-13-libatomic-devel"

DEB_DEP_PKGS=""

SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — apply ppc64le patch and fix cmake/codegen compatibility
# =============================================================================
post_clone() {
    local patch_version="${PACKAGE_VERSION#v}"  # strip leading 'v'
    local patch_file="${SCRIPT_DIR}/pytorch_v${patch_version}.patch"
    if [[ ! -f "${patch_file}" ]]; then
        patch_file="${SCRIPT_DIR}/pytorch_v2.6.0.patch"
    fi
    log_info "Applying ppc64le patch from ${patch_file}..."

    if [[ -f "${patch_file}" ]]; then
        if git apply --check "${patch_file}" 2>/dev/null; then
            log_info "Applying ppc64le patch (VSX intrinsics, POWER arch detection, CMake, CVE fixes)..."
            git apply "${patch_file}"
            log_info "Applied ppc64le patch successfully"
        else
            log_warn "Patch may already be applied or conflicts exist, continuing..."
        fi
    else
        log_warn "No patch file found for ${PACKAGE_VERSION}, continuing without patch..."
        log_warn "ppc64le-specific fixes (VSX intrinsics, etc.) will not be applied"
    fi

    # Fix CMake compatibility in bundled third_party libraries
    # CMake 3.27+ removed backwards compatibility for cmake_minimum_required < 3.5
    # Even with BUILD_CUSTOM_PROTOBUF=OFF, CMake still parses these files during configure
    log_info "Fixing cmake_minimum_required in third_party for CMake 3.27+ compatibility..."
    find third_party -name "CMakeLists.txt" -exec grep -l "cmake_minimum_required" {} \; | while read -r cmakefile; do
        # Replace cmake_minimum_required(VERSION X.Y) where X.Y < 3.5 with VERSION 3.5
        if grep -qE "cmake_minimum_required\s*\(\s*VERSION\s+[0-2]\." "$cmakefile" 2>/dev/null; then
            log_info "  Patching: $cmakefile"
            sed -i -E 's/cmake_minimum_required\s*\(\s*VERSION\s+[0-2]\.[0-9]+(\.[0-9]+)?/cmake_minimum_required(VERSION 3.5/' "$cmakefile"
        elif grep -qE "cmake_minimum_required\s*\(\s*VERSION\s+3\.[0-4](\s|\))" "$cmakefile" 2>/dev/null; then
            log_info "  Patching: $cmakefile"
            sed -i -E 's/cmake_minimum_required\s*\(\s*VERSION\s+3\.[0-4]([^0-9])/cmake_minimum_required(VERSION 3.5\1/' "$cmakefile"
        fi
    done

    # Fix cmake version requirement in requirements.txt
    # PyTorch requires specific cmake version but we build cmake ourselves
    if [[ -f requirements.txt ]]; then
        sed -i "s/cmake/cmake==3.*/g" requirements.txt
    fi

    # Fix GCC 13 missing <stdexcept> in c10/util/Registry.h
    # GCC 13 (UBI:9.6) no longer transitively includes <stdexcept> via other headers,
    # so std::runtime_error is not in scope. Add the missing include explicitly.
    if [[ -f "c10/util/Registry.h" ]]; then
        if ! grep -q '#include <stdexcept>' c10/util/Registry.h; then
            log_info "Adding missing #include <stdexcept> to c10/util/Registry.h..."
            sed -i '/#include <c10\/util\/Type.h>/a #include <stdexcept>' c10/util/Registry.h
        fi
    fi

    # Fix generated header issues for ppc64le (special_i1, special_expit ops)
    # These ops have code generation issues on ppc64le in v2.6.0
    log_info "Applying ppc64le codegen fixes for special ops..."
    if [[ -f "aten/src/ATen/native/native_functions.yaml" ]]; then
        # Ensure special_i1 and special_expit have proper declarations
        # This addresses "expected class-name before '{' token" and
        # "'at::_ops::special_i1' has not been declared" errors
        sed -i '/^  - func: special_i1(/a\    dispatch:\n      CPU: true' aten/src/ATen/native/native_functions.yaml 2>/dev/null || true
        sed -i '/^  - func: special_expit(/a\    dispatch:\n      CPU: true' aten/src/ATen/native/native_functions.yaml 2>/dev/null || true
    fi
}

# =============================================================================
# CALLBACK: custom_install — build PyTorch wheel and install to artifact directory (CPU-only, ppc64le)
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir pytorch "${PACKAGE_VERSION}")"

    # Check if already built (idempotency)
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "PyTorch artifact already exists at ${ARTIFACT_DIR}"
        false  # force non-zero to surface this as an unexpected condition if needed, or simply return
        return
    fi

    # -------------------------------------------------------------------------
    # Step 1: Source required dependency artifacts
    # -------------------------------------------------------------------------
    log_info "Sourcing dependency artifacts (openblas, abseil-cpp, libprotobuf, numpy)..."
    source_artifact openblas || { log_error "openblas artifact not found! Build openblas first: o/openblas/openblas.sh"; false; }
    source_artifact abseil-cpp 20240116.2 || { log_error "abseil-cpp artifact not found! Build abseil-cpp first: a/abseil-cpp/abseil-cpp.sh"; false; }
    # Without this artifact PyTorch silently falls back to its bundled protobuf 3.13,
    # which later breaks auditwheel repair (libprotobuf.so.3.13.0.0 not found)
    source_artifact libprotobuf v26.1 || { log_error "libprotobuf artifact not found! Build libprotobuf first: l/libprotobuf/libprotobuf.sh"; false; }
    source_artifact numpy v2.2.5 || { log_error "numpy artifact not found! Build numpy first: n/numpy/numpy.sh"; false; }

    log_info "Building PyTorch ${PACKAGE_VERSION} to ${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}"

    # -------------------------------------------------------------------------
    # Step 2: Install Python build dependencies
    # -------------------------------------------------------------------------
    log_info "Installing Python build dependencies..."
    python -m pip install --upgrade pip setuptools wheel protobuf
    python -m pip install -r requirements.txt
    python -m pip install pyyaml typing_extensions

    # -------------------------------------------------------------------------
    # Step 3: Configure PyTorch build environment
    # This is the critical section - ~50 variables control the build
    # Note: gcc-toolset-13 and rust toolchain are provided by container
    # -------------------------------------------------------------------------
    local arch
    arch=$(uname -m)
    local cpu_opt_arch="native"
    local cpu_opt_tune="native"

    # ppc64le-specific CPU optimizations
    if [[ "${arch}" == "ppc64le" ]]; then
        cpu_opt_arch="power9"
        cpu_opt_tune="power10"
    fi

    # --- BLAS Configuration ---
    # Ensure CMake can find OpenBLAS
    # The openblas env.sh doesn't set CMAKE_PREFIX_PATH, so we add it explicitly
    export BLAS=OpenBLAS
    if [[ -n "${OPENBLAS_PREFIX:-}" ]]; then
        export CMAKE_PREFIX_PATH="${OPENBLAS_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    fi

    # --- Abseil Configuration ---
    # Ensure CMake can find Abseil (required by protobuf)
    # The abseil-cpp env.sh doesn't set CMAKE_PREFIX_PATH, so we add it explicitly
    if [[ -n "${ABSEIL_CPP_PREFIX:-}" ]]; then
        export CMAKE_PREFIX_PATH="${ABSEIL_CPP_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    fi

    # --- Protobuf Configuration ---
    # Ensure CMake find_package(Protobuf CONFIG) resolves to the libprotobuf artifact
    if [[ -n "${LIBPROTOBUF_PREFIX:-}" ]]; then
        export CMAKE_PREFIX_PATH="${LIBPROTOBUF_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    fi
    export BUILD_CUSTOM_PROTOBUF=OFF

    # --- CPU-Only Build (disable all GPU/accelerator support) ---
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_TENSORRT=0
    export USE_ROCM=0

    # --- Disable x86-specific libraries (not available on ppc64le) ---
    export USE_FBGEMM=0       # Facebook GEMM - x86 AVX/AVX2 only
    export USE_MKLDNN=0       # Intel MKL-DNN - x86 only
    export USE_NNPACK=0       # Neural Network Pack - x86 SIMD only
    export USE_QNNPACK=0      # Quantized NNPACK - x86 only
    export USE_XNNPACK=0      # Google's XNNPACK - x86/ARM only
    export USE_PYTORCH_QNNPACK=0

    # --- Build Options ---
    export TH_BINARY_BUILD=1
    export USE_LMDB=1
    export USE_LEVELDB=1
    export USE_NINJA=0        # Use make instead of ninja for better error messages
    export USE_MPI=0
    export USE_OPENMP=1       # Enable OpenMP for ppc64le performance
    export USE_TBB=0
    export USE_SYSTEM_NCCL=1
    export BUILD_CAFFE2=1

    # --- Version Information ---
    export PYTORCH_BUILD_VERSION="${PACKAGE_VERSION#v}"
    export PYTORCH_BUILD_NUMBER="1"

    # --- Compiler Flags ---
    export CPU_COUNT=$(nproc --all)
    export CXXFLAGS="${CXXFLAGS:-} -D__STDC_FORMAT_MACROS -fplt"
    export CFLAGS="${CFLAGS:-} -fplt"

    # Add CPU architecture optimization flags
    export CXXFLAGS="${CXXFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
    export CFLAGS="${CFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"

    # Fix linker flags (use artifact PREFIX variables)
    export LDFLAGS="$(echo ${LDFLAGS:-} | sed -e 's/-Wl\,--as-needed//')"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${OPENBLAS_PREFIX}/lib"

    # --- For setuptools_scm version detection ---
    export SETUPTOOLS_SCM_PRETEND_VERSION="${PYTORCH_BUILD_VERSION}"

    # -------------------------------------------------------------------------
    # Step 4: Build and install PyTorch
    # NOTE: PyTorch uses setup.py, NOT python -m build (PEP 517)
    # -------------------------------------------------------------------------

    # --- Memory Management ---
    # PyTorch C++ compilation is extremely memory-intensive due to heavy templates.
    # Each parallel job can consume 2-8GB RAM. Calculate MAX_JOBS based on available memory.
    # Target: ~10GB per job to avoid OOM kills.
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    # PyTorch's heaviest generated TUs (RegisterCompositeExplicitAutograd_*.cpp,
    # VariableType_*.cpp) each need 8-12 GB.  Using 4 GB/job causes OOM kills on
    # those files even when total RAM looks sufficient.  Use 10 GB/job and cap
    # at a hard maximum of 8 jobs to avoid OOM killer on large multi-core hosts.
    local mem_per_job_gb=10
    local max_jobs_by_mem=$((total_mem_gb / mem_per_job_gb))
    local cpu_count
    cpu_count=$(nproc --all)

    if [[ ${max_jobs_by_mem} -lt 1 ]]; then
        max_jobs_by_mem=1
    fi
    # Cap at cpu_count
    if [[ ${max_jobs_by_mem} -gt ${cpu_count} ]]; then
        max_jobs_by_mem=${cpu_count}
    fi
    # Hard cap at 8 parallel jobs to avoid memory exhaustion from simultaneous heavy translation units
    local max_allowed_jobs=8
    if [[ ${max_jobs_by_mem} -gt ${max_allowed_jobs} ]]; then
        max_jobs_by_mem=${max_allowed_jobs}
    fi

    export MAX_JOBS=${max_jobs_by_mem}
    export CPU_COUNT=${max_jobs_by_mem}
    # MAKEFLAGS is read by setup.py's internal make invocation
    export MAKEFLAGS="-j${max_jobs_by_mem}"

    log_info "Building PyTorch (this will take 2 hours)..."
    log_info "Total memory: ${total_mem_gb}GB, CPU cores: ${cpu_count}"
    log_info "Limiting parallel jobs to MAX_JOBS=${MAX_JOBS} (capped at max ${max_allowed_jobs} jobs)"

    # --- CMake arguments (passed via CMAKE_ARGS environment variable) ---
    # CMAKE_POLICY_VERSION_MINIMUM=3.5 fixes "Compatibility with CMake < 3.5 removed" errors
    # BUILD_CUSTOM_PROTOBUF=OFF ensures we use our artifact protobuf
    # CMAKE_BUILD_PARALLEL_LEVEL overrides any -j the CI template appends to cmake --build
    export CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_CUSTOM_PROTOBUF=OFF"
    export CMAKE_BUILD_PARALLEL_LEVEL=${max_jobs_by_mem}

    # Build wheel into dist/ (templates/python.sh will automatically detect and process it into output artifacts)
    mkdir -p dist
    log_info "Building PyTorch wheel into dist/..."
    python setup.py bdist_wheel --dist-dir dist

    # Install to artifact directory for dependent packages (reuses already-compiled objects in build/)
    log_info "Installing PyTorch into artifact directory ${ARTIFACT_DIR}..."
    python setup.py install --prefix="${ARTIFACT_DIR}"

    # -------------------------------------------------------------------------
    # Step 5: Organize artifact directory structure
    # PyTorch provides:
    #   - Python package (torch/) in site-packages
    #   - Native libraries (libtorch.so, libc10.so, etc.)
    #   - C++ headers for dependent packages (ATen, c10, torch)
    # -------------------------------------------------------------------------
    log_info "Organizing artifact directory..."

    # Find the installed site-packages directory
    local site_packages
    site_packages=$(python -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || echo "")

    if [[ -z "${site_packages}" ]]; then
        # Fallback: search in artifact directory
        site_packages=$(find "${ARTIFACT_DIR}" -type d -name "site-packages" | head -1)
    fi

    # Copy license
    cp LICENSE "${ARTIFACT_DIR}/"

    # -------------------------------------------------------------------------
    # Step 6: Generate env.sh for dependent packages
    # This allows torchvision, torchaudio, etc. to find PyTorch
    # -------------------------------------------------------------------------
    local python_version
    python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

    cat > "${ARTIFACT_DIR}/env.sh" << EOF
    # PyTorch ${PACKAGE_VERSION} environment
    # Tier 2 artifact - depends on openblas, abseil-cpp

export PYTORCH_PREFIX="${ARTIFACT_DIR}"
export TORCH_HOME="${ARTIFACT_DIR}"

# Python package location
export PYTHONPATH="${ARTIFACT_DIR}/lib/python${python_version}/site-packages:\${PYTHONPATH:-}"

# Native library paths
export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LIBRARY_PATH:-}"

# C++ header paths (for torchvision, torchaudio, etc.)
export CPATH="${ARTIFACT_DIR}/include:\${CPATH:-}"
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"

# Torch-specific variables used by dependent builds
export TORCH_INSTALL_PREFIX="${ARTIFACT_DIR}"
export Torch_DIR="${ARTIFACT_DIR}/share/cmake/Torch"

# Propagate CPU-only build settings to dependents
export USE_CUDA=0
export USE_CUDNN=0
EOF

    # -------------------------------------------------------------------------
    # Step 7: Generate manifest for license compliance and reproducibility
    # -------------------------------------------------------------------------
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "pytorch" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "BSD-3-Clause" \
        "openblas"

    log_info "PyTorch installed to ${ARTIFACT_DIR}"
    log_info "Build completed successfully!"
}

SKIP_TESTS="true"

# =============================================================================
# CALLBACK: custom_test_command — smoke-test torch import (full test suite skipped for artifact build)
# =============================================================================
custom_test_command() {
    log_info "Verifying torch package import (full test suite skipped)"
    python -c "import torch; print('torch version:', torch.__version__)"
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
