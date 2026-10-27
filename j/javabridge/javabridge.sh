#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : javabridge
# Version       : master
# Source repo   : https://github.com/LeeKamentsky/python-javabridge
# Tested on     : UBI 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - javabridge is a Python/Java bridge using JNI
#   - Requires Java 11 OpenJDK and JAVA_HOME to be set
#   - Uses Cython (<3) for building C extensions
#   - Tests use deprecated nosetests framework - incompatible with Python 3.12+
#   - Repository directory differs from package name (python-javabridge vs javabridge)
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="javabridge"
PACKAGE_VERSION="${1:-1.0.19}"
PACKAGE_URL="https://github.com/LeeKamentsky/python-javabridge"

# Clone directory differs from package name
CLONE_DIR="python-javabridge"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building javabridge
# Note: rust/cargo, gcc are provided by container; java-11-openjdk required
# =============================================================================
RH_DEP_PKGS="git make cmake gcc gcc-c++ zlib-devel libjpeg-devel openssl-devel freetype-devel libyaml-devel java-11-openjdk java-11-openjdk-devel python3-devel python3-pip"
DEB_DEP_PKGS="git make cmake gcc g++ zlib1g-dev libjpeg-dev libssl-dev libfreetype6-dev libyaml-dev openjdk-11-jdk python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git make cmake gcc gcc-c++ zlib-devel libjpeg-devel libopenssl-devel freetype-devel libyaml-devel java-11-openjdk java-11-openjdk-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_clone
# Set up Java environment before any operations
# =============================================================================
pre_clone() {
    log_info "Setting up Java environment..."

    # Set JAVA_HOME - required for javabridge to find JNI headers
    if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-ppc64le" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-ppc64le"
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-s390x" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-s390x"
    else
        # Try to find any java-11 installation
        JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) || true
        export JAVA_HOME
    fi

    if [[ -z "$JAVA_HOME" ]] || [[ ! -d "$JAVA_HOME" ]]; then
        log_error "JAVA_HOME could not be determined"
        return 1
    fi

    export PATH="$JAVA_HOME/bin:$PATH"
    log_info "JAVA_HOME set to: $JAVA_HOME"

    # Enable gcc-toolset-13 if available (RHEL/UBI specific)
    if [[ -f "/opt/rh/gcc-toolset-13/enable" ]]; then
        log_info "Enabling gcc-toolset-13..."
        source /opt/rh/gcc-toolset-13/enable
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install build dependencies (Cython, numpy) before building.
# Cython < 3 is required for compatibility with this version of javabridge.
# NumPy < 2.0 is required to avoid NumPy 2.x compatibility issues.
# Note: This runs INSIDE .venv-build, so pip install works correctly.
# =============================================================================
pre_build() {
    log_info "Installing Cython and numpy for javabridge build..."

    # javabridge requires Cython < 3 for compatibility
    # Use python -m pip to ensure venv usage
    python -m pip install "cython<3" wheel "setuptools<70" "numpy<2"

    # Cythonize the pyx files so they are present when the sdist is generated.
    # Because setuptools tries to package them via MANIFEST.in but prunes the pyx files,
    # the .c files must exist before sdist creation/packaging begins.
    log_info "Generating C files from Cython sources..."
    python -m cython -3 _javabridge.pyx _javabridge_nomac.pyx _javabridge_mac.pyx

    # Ensure JAVA_HOME is still set (venv activation may have cleared it)
    if [[ -z "$JAVA_HOME" ]]; then
        if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-ppc64le" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-ppc64le"
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-s390x" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-s390x"
        fi
        export PATH="$JAVA_HOME/bin:$PATH"
    fi

    log_info "Using JAVA_HOME: $JAVA_HOME"
}

# =============================================================================
# CALLBACK: pre_test
# Ensure build and runtime dependencies (Cython < 3, numpy < 2.0) are installed
# in the test environment before building/installing the package.
# We also run with PIP_NO_BUILD_ISOLATION=true (exported in pre_clone) to prevent
# pip from using isolated builds which would download incompatible numpy 2.x.
# =============================================================================
pre_test() {
    log_info "Pre-installing build and runtime dependencies in the test environment..."
    python -m pip install "cython<3" wheel "setuptools<70" "numpy<2"
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests inside the repository using Python's isolated mode (-I) and pytest's
# importlib mode to prevent import shadowing of the compiled C extension.
# We generate a local conftest.py to initialize the JVM, load all bundled jar
# archives (handling lib64/lib splits), and monkey-patch assertEquals/assertNotEquals
# for Python 3.12+ compatibility, cleaning it up after pytest completes.
# =============================================================================
custom_test_command() {
    # Create conftest.py to initialize JVM and monkey-patch deprecated unittest methods
    cat << 'EOF' > conftest.py
import javabridge
import os
import unittest

# Restore assertEquals and assertNotEquals removed in Python 3.12
if not hasattr(unittest.TestCase, "assertEquals"):
    unittest.TestCase.assertEquals = unittest.TestCase.assertEqual
if not hasattr(unittest.TestCase, "assertNotEquals"):
    unittest.TestCase.assertNotEquals = unittest.TestCase.assertNotEqual

def pytest_configure(config):
    # Resolve potential lib64/lib split on RedHat/UBI systems where
    # C extensions are in lib64 but package data (jars) is in lib.
    # Scan both locations for any .jar files (including test.jar) and add them to class_path.
    class_path = []
    pkg_dir = os.path.dirname(javabridge.__file__)
    for base_dir in [pkg_dir, pkg_dir.replace('lib64', 'lib'), pkg_dir.replace('lib', 'lib64')]:
        jars_dir = os.path.join(base_dir, "jars")
        if os.path.exists(jars_dir):
            for file in os.listdir(jars_dir):
                if file.endswith('.jar'):
                    full_path = os.path.normpath(os.path.join(jars_dir, file))
                    if full_path not in class_path and os.path.exists(full_path):
                        class_path.append(full_path)
                        
    javabridge.start_vm(run_headless=True, class_path=class_path)

def pytest_unconfigure(config):
    javabridge.kill_vm()
EOF

    python -I -m pytest --import-mode=importlib --pyargs javabridge.tests
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
