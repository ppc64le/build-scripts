#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pystan
# Version       : 3.10.0
# Source repo   : https://github.com/stan-dev/pystan
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pystan"
PACKAGE_VERSION="${1:-3.10.0}"
PACKAGE_URL="https://github.com/stan-dev/pystan"

CMDSTAN_VERSION="${CMDSTAN_VERSION:-v2.35.0}"
HTTPSTAN_VERSION="${HTTPSTAN_VERSION:-4.13.0}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make openssl-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# httpstan requires Python >=3.12. Override python3 so the template's venv
# is created with 3.12 when the entrypoint hasn't already set up the shim.
if command -v python3.12 &>/dev/null && ! python3 --version 2>/dev/null | grep -q "3\.1[2-9]"; then
    python3() { python3.12 "$@"; }
    export -f python3
fi

# =============================================================================
# CALLBACK: custom_install
# Manages the full build phase:
# 1. Clone and build cmdstan; copy stanc into httpstan clone.
# 2. Run `make` in httpstan to compile precompiled Stan objects.
# 3. Install httpstan from local source into build venv.
# 4. Build pystan wheel via poetry (template processes dist/ automatically).
# =============================================================================
custom_install() {
    local build_root
    build_root="$(dirname "$(dirname "${VIRTUAL_ENV}")")"

    log_info "Cloning and building cmdstan ${CMDSTAN_VERSION}"
    git clone https://github.com/stan-dev/cmdstan "${build_root}/cmdstan"
    pushd "${build_root}/cmdstan"
    git checkout "${CMDSTAN_VERSION}"
    git submodule update --init --recursive
    make build -j"$(nproc)"
    export PATH="${build_root}/cmdstan/bin:${PATH}"
    popd

    log_info "Cloning httpstan ${HTTPSTAN_VERSION}"
    git clone --branch "${HTTPSTAN_VERSION}" --depth 1 https://github.com/stan-dev/httpstan "${build_root}/httpstan"

    log_info "Copying stanc binary into httpstan source"
    cp "${build_root}/cmdstan/bin/stanc" "${build_root}/httpstan/httpstan/stanc"
    chmod +x "${build_root}/httpstan/httpstan/stanc"

    log_info "Building httpstan (compiles precompiled Stan objects via make)"
    pushd "${build_root}/httpstan"
    make -j"$(nproc)"
    popd

    log_info "Resolving Python include path"
    local python_include
    python_include="$(python -c "from sysconfig import get_paths; print(get_paths()['include'])")"
    export CPLUS_INCLUDE_PATH="${python_include}:${CPLUS_INCLUDE_PATH:-}"
    export C_INCLUDE_PATH="${python_include}:${C_INCLUDE_PATH:-}"

    log_info "Installing httpstan from local source"
    python -m pip install "${build_root}/httpstan"

    log_info "Copying stanc binary into installed httpstan package"
    local httpstan_pkg
    httpstan_pkg="$(python -c "import httpstan, os; print(os.path.dirname(httpstan.__file__))")"
    cp "${build_root}/cmdstan/bin/stanc" "${httpstan_pkg}/stanc"
    chmod +x "${httpstan_pkg}/stanc"

    log_info "Installing pysimdjson (not pulled in transitively by httpstan)"
    python -m pip install pysimdjson

    log_info "Building pystan wheel via poetry"
    python -m pip install "poetry==1.7.1"
    poetry build -v
}

# =============================================================================
# CALLBACK: pre_test
# Install httpstan from local source into test venv and apply ppc64le patches.
# =============================================================================
pre_test() {
    local build_root
    build_root="$(dirname "$(dirname "${VIRTUAL_ENV}")")"

    log_info "Resolving Python include path for httpstan C++ compilation"
    local python_include
    python_include="$(python -c "from sysconfig import get_paths; print(get_paths()['include'])")"
    export CPLUS_INCLUDE_PATH="${python_include}:${CPLUS_INCLUDE_PATH:-}"
    export C_INCLUDE_PATH="${python_include}:${C_INCLUDE_PATH:-}"

    log_info "Installing httpstan from local source into test venv"
    python -m pip install "${build_root}/httpstan"

    log_info "Copying stanc binary into installed httpstan package"
    local httpstan_pkg
    httpstan_pkg="$(python -c "import httpstan, os; print(os.path.dirname(httpstan.__file__))")"
    cp "${build_root}/cmdstan/bin/stanc" "${httpstan_pkg}/stanc"
    chmod +x "${httpstan_pkg}/stanc"

    log_info "Patching httpstan models.py: remove _GLIBCXX_USE_CXX11_ABI=0 (breaks gcc-toolset-13 on ppc64le)"
    sed -i '/("_GLIBCXX_USE_CXX11_ABI", "0")/d' "${httpstan_pkg}/models.py"

    log_info "Patching httpstan compile.py: increase stanc timeout for ppc64le"
    sed -i 's/timeout=1/timeout=60/' "${httpstan_pkg}/compile.py"

    log_info "Installing test dependencies"
    python -m pip install pandas "pytest-asyncio>=0.18.3"
}

# =============================================================================
# CALLBACK: custom_test_command
# Most upstream tests call stan.build() which compiles a Stan C++ extension at
# runtime via httpstan.
# Only tests that do not trigger runtime C++ compilation are run here.
# =============================================================================
custom_test_command() {
    log_info "Running pystan smoke tests (runtime C++ compilation tests skipped on ppc64le)"
    python -m pytest --import-mode=importlib -o "addopts=" -v \
        tests/test_httpstan_health.py \
        tests/test_build_exceptions.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

