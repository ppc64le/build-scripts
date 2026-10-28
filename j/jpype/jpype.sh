#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jpype
# Version       : v1.5.0
# Source repo   : https://github.com/jpype-project/jpype
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - JPype is a Java-Python bridge requiring OpenJDK 11
#   - JDBC drivers (sqlite-jdbc, hsqldb, h2) are downloaded for tests
#   - Java test fixtures are compiled before running tests
#   - Container environment provides: gcc/g++, cmake, cargo
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jpype"
PACKAGE_VERSION="${1:-v1.5.0}"
PACKAGE_URL="https://github.com/jpype-project/jpype"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building jpype
# Note: gcc/g++, cmake, cargo are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip java-11-openjdk java-11-openjdk-devel openssl-devel openblas-devel bzip2-devel libffi-devel zlib-devel sqlite-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv openjdk-11-jdk libssl-dev libopenblas-dev libbz2-dev libffi-dev zlib1g-dev libsqlite3-dev"
SLES_DEP_PKGS="git python3-devel python3-pip java-11-openjdk java-11-openjdk-devel libopenssl-devel openblas-devel libbz2-devel libffi-devel zlib-devel sqlite3-devel"

# =============================================================================
# CALLBACK: pre_clone
# Set up Java environment before build
# =============================================================================
pre_clone() {
    log_info "Setting up Java environment..."

    # Set JAVA_HOME based on distribution
    if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-ppc64el" ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-ppc64el
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    elif [[ -d "/usr/lib/jvm/java-11-openjdk-s390x" ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x
    else
        # Try to find any java-11 installation
        JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        if [[ ! -d "$JAVA_HOME" ]]; then
            log_error "Could not find Java 11 installation"
            return 1
        fi
    fi

    export PATH=$JAVA_HOME/bin:$PATH
    log_info "JAVA_HOME set to: $JAVA_HOME"
    log_info "Java version: $(java -version 2>&1 | head -n1)"
}

# =============================================================================
# CALLBACK: post_clone
# Download JDBC drivers needed for tests
# =============================================================================
post_clone() {
    log_info "Downloading JDBC drivers for tests..."

    # Download JDBC drivers to the repo directory
    wget -q https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.42.0.0/sqlite-jdbc-3.42.0.0.jar -O sqlite-jdbc.jar || {
        log_error "Failed to download sqlite-jdbc"
        return 1
    }
    wget -q https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.7.2/hsqldb-2.7.2.jar -O hsqldb.jar || {
        log_error "Failed to download hsqldb"
        return 1
    }
    wget -q https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar -O h2.jar || {
        log_error "Failed to download h2"
        return 1
    }

    log_info "JDBC drivers downloaded successfully"
}

# =============================================================================
# CALLBACK: pre_build
# Set environment for build with Java support
# =============================================================================
pre_build() {
    log_info "Setting up build environment with Java support..."

    # Ensure JAVA_HOME is set (may not persist from pre_clone in subshell)
    if [[ -z "$JAVA_HOME" ]]; then
        if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-ppc64el" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-ppc64el
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-s390x" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x
        else
            export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        fi
    fi
    export PATH=$JAVA_HOME/bin:$PATH

    log_info "JAVA_HOME: $JAVA_HOME"
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with Java fixtures and JDBC drivers
# =============================================================================
custom_test_command() {
    log_info "Setting up Java environment for tests..."

    # Ensure JAVA_HOME is set
    if [[ -z "$JAVA_HOME" ]]; then
        if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-ppc64el" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-ppc64el
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-s390x" ]]; then
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x
        else
            export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        fi
    fi
    export PATH=$JAVA_HOME/bin:$PATH

    log_info "Installing test dependencies..."
    pip install pytest pytest-cov numpy jedi typing_extensions || true

    # Version-specific numpy handling
    if [[ "$PACKAGE_VERSION" == "v1.5.0" ]]; then
        pip install "numpy<2" || true
    fi

    # Install test requirements if available
    if [[ -f "test-requirements.txt" ]]; then
        pip install -r test-requirements.txt || true
    fi

    # Remove plugins that may cause issues
    pip uninstall -y pytest-cov pytest-xdist 2>/dev/null || true

    log_info "Compiling Java test fixtures..."
    mkdir -p test/classes
    find test -name "*.java" | xargs javac -source 8 -target 8 -d test/classes 2>/dev/null || {
        log_warn "Some Java fixtures failed to compile, continuing..."
    }

    # Set up CLASSPATH with fixtures and JDBC jars
    export CLASSPATH="$(pwd)/test/classes:$(pwd)/h2.jar:$(pwd)/hsqldb.jar:$(pwd)/sqlite-jdbc.jar"
    export JPYPE_JVM_ARGS="-Djava.class.path=$CLASSPATH"

    log_info "CLASSPATH: $CLASSPATH"
    log_info "Running JPype tests..."

    # Verify jpype import works
    python -c "import jpype; import _jpype; print('JPype native module loaded OK')" || {
        log_error "Failed to import jpype"
        return 1
    }

    # Run tests with jpype-specific flags
    # --checkjni: Enable JNI checking
    # --fast: Skip slow tests
    pytest \
        -o "addopts=" \
        -v \
        test/jpypetest \
        --checkjni \
        --fast \
        --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
