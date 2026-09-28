#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bazel
# Version       : 5.3.2
# Source repo   : https://github.com/bazelbuild/bazel
# Tested on     : UBI 9.6
# Language      : Java
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="bazel"
PACKAGE_VERSION="${1:-8.0.0}"
PACKAGE_URL="https://github.com/bazelbuild/bazel"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="bazel"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# JDK is version-specific — injected by pre_packages() below based on MAJOR_VER.
# Bazel 5.x → Java 11, Bazel 6–7 → Java 17, Bazel 8+ → Java 21.
RH_DEP_PKGS="git gcc gcc-c++ make wget unzip zip python3 patch"
DEB_DEP_PKGS="git gcc g++ make wget unzip zip python3 patch"
SLES_DEP_PKGS="git gcc gcc-c++ make wget unzip zip python3 patch"

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="custom"  # Bazel bootstraps itself via compile.sh, not maven/gradle
SKIP_TESTS=true
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# CALLBACK: pre_packages — inject the correct JDK for this Bazel version only
# =============================================================================
pre_packages() {
    local major
    major="$(echo "${PACKAGE_VERSION}" | cut -d. -f1)"

    local jdk_ver
    if [[ "${major}" -lt 6 ]]; then
        jdk_ver=11
    elif [[ "${major}" -lt 8 ]]; then
        jdk_ver=17
    else
        jdk_ver=21
    fi
    log_info "Bazel ${PACKAGE_VERSION}: installing Java ${jdk_ver} JDK"

    if command -v dnf &>/dev/null; then
        dnf install -y "java-${jdk_ver}-openjdk" "java-${jdk_ver}-openjdk-devel"
    elif command -v apt-get &>/dev/null; then
        apt-get install -y -q "openjdk-${jdk_ver}-jdk"
    elif command -v zypper &>/dev/null; then
        zypper install -y "java-${jdk_ver}-openjdk" "java-${jdk_ver}-openjdk-devel"
    fi
}

# =============================================================================
# CALLBACK: post_clone - Download dist zip and apply patch
# =============================================================================
post_clone() {
    # Download and extract dist zip (required for bootstrap, git clone won't work alone)
    local DIST_URL="https://github.com/bazelbuild/bazel/releases/download/${PACKAGE_VERSION}/bazel-${PACKAGE_VERSION}-dist.zip"

    log_info "Downloading Bazel ${PACKAGE_VERSION} dist zip..."
    if ! wget -q "$DIST_URL" -O "bazel-dist.zip"; then
        log_error "Failed to download Bazel dist zip from ${DIST_URL}"
    fi

    log_info "Extracting Bazel dist zip..."
    if ! unzip -o -q "bazel-dist.zip"; then
        log_error "Failed to extract Bazel dist zip"
    fi
    rm "bazel-dist.zip"

    # Verify critical files exist
    if [[ ! -f "compile.sh" ]]; then
        log_error "compile.sh not found after dist zip extraction"
    fi

    # Bazel 5.x: cc_toolchain_config.bzl hardcodes -std=c++0x; abseil lts_20211102
    # requires C++17 for scoped-enum forward declarations with underlying types.
    # Patch all bzl/BUILD files in the dist zip that embed this flag.
    # (The GCC compiler used during bootstrap is separately controlled in
    # custom_install() — see the CC/CXX override for Bazel < 6.)
    local _major
    _major="$(echo "${PACKAGE_VERSION}" | cut -d. -f1)"
    if [[ "${_major}" -lt 6 ]]; then
        log_info "Patching C++ standard flags: -std=c++0x → -std=c++17 (Bazel 5.x / abseil C++17 requirement)"
        find . \( -name "*.bzl" -o -name "*.bazel" -o -name "BUILD" -o -name "BUILD.bazel" \) \
            -print0 | xargs -0 grep -rl -- '-std=c++0x\|-std=gnu++0x' 2>/dev/null | \
            xargs -r sed -i 's/-std=c++0x/-std=c++17/g; s/-std=gnu++0x/-std=gnu++17/g'
    fi

    # Apply Bazel 8.0.0 bootstrap patch if building version 8.0.0
    if [[ "${PACKAGE_VERSION}" == "8.0.0" ]]; then
        log_info "Applying Bazel 8.0.0 bootstrap patch..."
        sed -i 's/new ElementWithSkippedAppends<T>(element, skippedAppendCount + 1)/new ElementWithSkippedAppends<T>(this.element(), this.skippedAppendCount() + 1)/g' \
		src/main/java/com/google/devtools/build/lib/concurrent/ConcurrentFifo.java
        if [[ -f "${SCRIPT_DIR}/bazel-8_0_0.patch" ]]; then
            if ! patch -p1 < "${SCRIPT_DIR}/bazel-8_0_0.patch"; then
                log_error "Failed to apply bootstrap patch for Bazel 8.0.0"
            fi
        else
            log_error "Patch file ${SCRIPT_DIR}/bazel-8_0_0.patch not found"
        fi
    fi
}

# =============================================================================
# CALLBACK: custom_install - Bootstrap build
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ ! -f "${ARTIFACT_DIR}/env.sh" ]]; then
        # Clear stale environment variables
        unset CLASSPATH
        unset _JAVA_OPTIONS
        unset JAVA_VERSION
        unset JAVA_TOOL_OPTIONS

        local MAJOR_VER
        MAJOR_VER="$(echo "${PACKAGE_VERSION}" | cut -d. -f1)"

        # Bazel 5.x uses StringUnsafe which reflectively accesses java.lang.String
        # internals — blocked by JEP 403 in Java 17+. Must use Java 11.
        # Bazel 6–7 require Java 17. Bazel 8+ requires Java 21.
        local REQUIRED_JAVA_VER
        if [[ "${MAJOR_VER}" -lt 6 ]]; then
            REQUIRED_JAVA_VER=11
        elif [[ "${MAJOR_VER}" -lt 8 ]]; then
            REQUIRED_JAVA_VER=17
        else
            REQUIRED_JAVA_VER=21
        fi
        log_info "Bazel ${PACKAGE_VERSION} requires Java ${REQUIRED_JAVA_VER}"

        # Locate the required JDK (must have javac, not just JRE)
        unset JAVA_HOME
        local candidate
        for candidate in \
            "/usr/lib/jvm/java-${REQUIRED_JAVA_VER}-openjdk" \
            "/usr/lib/jvm/java-${REQUIRED_JAVA_VER}" \
            "$(find /usr/lib/jvm -maxdepth 1 -type d -name "*java-${REQUIRED_JAVA_VER}*" 2>/dev/null | head -1)"; do
            if [[ -x "${candidate}/bin/javac" ]]; then
                export JAVA_HOME="${candidate}"
                break
            fi
        done

        [[ -z "${JAVA_HOME}" || ! -x "${JAVA_HOME}/bin/javac" ]] && \
            log_error "Could not find Java ${REQUIRED_JAVA_VER} JDK (need javac, not just JRE)" && \
            log_error "Install with: dnf install java-${REQUIRED_JAVA_VER}-openjdk-devel"

        export PATH="${JAVA_HOME}/bin:${PATH}"
        export JAVA_VERSION="${REQUIRED_JAVA_VER}"
        export LOCAL_JAVA_HOMES="${JAVA_HOME}"

        log_info "Using JAVA_HOME=${JAVA_HOME} ($(${JAVA_HOME}/bin/java -version 2>&1 | head -1))"

        log_info "Building Bazel from source..."

        local BAZEL_BOOTSTRAP_ARGS=""
        local _bootstrap_cc=""
        local _bootstrap_cxx=""

        if [[ "${MAJOR_VER}" -ge 8 ]]; then
            # Java 21: explicit language/runtime version flags
            BAZEL_BOOTSTRAP_ARGS="--java_language_version=21 --tool_java_language_version=21 --java_runtime_version=local_jdk --tool_java_runtime_version=local_jdk --action_env=JAVA_HOME --action_env=PATH"
        elif [[ "${MAJOR_VER}" -ge 6 ]]; then
            # Java 17 (Bazel 6–7): pass --add-opens via JAVA_TOOL_OPTIONS so both
            # the bootstrap JVM and the Bazel-with-Bazel JVM honour the flag.
            BAZEL_BOOTSTRAP_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk"
            export JAVA_TOOL_OPTIONS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED"
        else
            # Java 11 (Bazel 5.x): pass --add-opens via JAVA_TOOL_OPTIONS so both
            # the bootstrap JVM and the Bazel-with-Bazel JVM honour the flag.
            BAZEL_BOOTSTRAP_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk"
            export JAVA_TOOL_OPTIONS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED"

            # Bazel 5.x on RHEL 9: gcc-toolset-13 is on PATH in the container, but
            # abseil lts_20211102 (bundled as external/com_google_absl during bootstrap)
            # is incompatible with GCC 13 — it requires C++17 and is missing
            # '#include <cstdint>'.  The known-working fix (from the legacy v1 script)
            # is to build Bazel 5.x with the system GCC (GCC 11 on RHEL 9), which is
            # lenient enough to compile this abseil version without those issues.
            # Override CC/CXX to /usr/bin/gcc so compile.sh and its embedded Bazel
            # invocation both use the system compiler, not gcc-toolset-13.
            if [[ -x "/usr/bin/gcc" ]]; then
                _bootstrap_cc="/usr/bin/gcc"
                _bootstrap_cxx="/usr/bin/g++"
                log_info "Bazel 5.x: using system GCC (${_bootstrap_cc}) to avoid gcc-toolset-13/abseil incompatibility"
            fi
        fi

        # Run compile.sh with updated arguments.
        # For Bazel 5.x only, _bootstrap_cc/cxx are set to /usr/bin/gcc to bypass gcc-toolset-13.
        if [[ -n "${_bootstrap_cc}" ]]; then
            env LOCAL_JAVA_HOMES="${JAVA_HOME}" EXTRA_BAZEL_ARGS="${BAZEL_BOOTSTRAP_ARGS}" \
                CC="${_bootstrap_cc}" CXX="${_bootstrap_cxx}" bash ./compile.sh
        else
            env LOCAL_JAVA_HOMES="${JAVA_HOME}" EXTRA_BAZEL_ARGS="${BAZEL_BOOTSTRAP_ARGS}" \
                bash ./compile.sh
        fi

        [[ ! -f "output/bazel" ]] && log_error "Bazel binary not found after build"

        log_info "Bazel built successfully"

        # Install to artifact directory
        mkdir -p "${ARTIFACT_DIR}/bin"
        cp output/bazel "${ARTIFACT_DIR}/bin/"
        chmod +x "${ARTIFACT_DIR}/bin/bazel"

        # Verify
        "${ARTIFACT_DIR}/bin/bazel" --version

        # Copy license
        _copy_license "${ARTIFACT_DIR}"

        # Generate env.sh
        cat > "${ARTIFACT_DIR}/env.sh" << EOF
export PATH="${ARTIFACT_DIR}/bin:\${PATH}"
EOF

        log_info "Created ${ARTIFACT_DIR}/env.sh"

        # Generate manifest
        generate_artifact_manifest "${ARTIFACT_DIR}" \
            "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
            "${PACKAGE_URL}" "${LICENSE_SPDX}"
    else
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
    fi
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
