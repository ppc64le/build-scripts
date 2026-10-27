#!/bin/bash
# =============================================================================
# java.sh - Invocable Java Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard Java build workflow with callback hooks for
# customization. Supports Maven, Gradle, Ant, and SBT.
#
# REQUIRED variables (must be set before sourcing):
#   PACKAGE_NAME    - Name of the package
#   PACKAGE_VERSION - Version to build (usually from $1)
#   PACKAGE_URL     - Git repository URL
#   RH_DEP_PKGS     - Red Hat/Fedora dependencies
#   DEB_DEP_PKGS    - Debian/Ubuntu dependencies (optional)
#   SLES_DEP_PKGS   - SUSE dependencies (optional)
#
# OPTIONAL variables:
#   JAVA_VERSION    - Preferred JDK version: 11, 17, 21 (default: auto-detect)
#   JDK_VERSIONS    - Space-separated JDK versions to try (default: "11 17 21")
#   MAVEN_VERSION   - Maven version to install (default: 3.9.9)
#   GRADLE_VERSION  - Gradle version to install (default: 8.2)
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   BUILD_TOOL      - Force build tool: maven, gradle, ant, sbt (default: auto)
#   NOARCH          - Set to "true" to fetch from Maven Central instead of building
#   MAVEN_GROUP_ID  - Maven group ID for NOARCH fetch (e.g., "org.apache.commons")
#   MAVEN_ARTIFACT_ID - Maven artifact ID if different from PACKAGE_NAME
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before build (environment setup)
#   post_build()           - After build, before test (verification)
#   custom_test_command()  - Override default test logic
#   post_test()            - After tests pass (cleanup, artifacts)
#   custom_build()         - Override entire build logic
#
# EXIT CODES:
#   0 - Success (build and test passed, or build passed with no tests)
#   1 - Clone or build failure
#   2 - Test failure (build succeeded)
# =============================================================================

# Ensure we're being sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/java.sh\""
    exit 1
fi

# =============================================================================
# SOURCE COMMON LIBRARIES
# =============================================================================
if [[ -z "${SCRIPT_DIR}" ]]; then
    echo "ERROR: SCRIPT_DIR must be set before sourcing this template"
    exit 1
fi

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${TEMPLATE_DIR}/lib/common.sh"
source "${TEMPLATE_DIR}/lib/distro-packages.sh"
source "${TEMPLATE_DIR}/lib/automation-stanzas.sh"
source "${TEMPLATE_DIR}/lib/prereq-checks.sh"
source "${TEMPLATE_DIR}/lib/container.sh"

# =============================================================================
# VALIDATE REQUIRED VARIABLES
# =============================================================================
validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL

# Set defaults for optional variables
: ${JAVA_VERSION:=""}
: ${JDK_VERSIONS:="11 17 21"}
: ${MAVEN_VERSION:="3.9.9"}
: ${GRADLE_VERSION:="8.2"}
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${BUILD_TOOL:=""}
: ${NOARCH:="false"}
: ${MAVEN_GROUP_ID:=""}
: ${MAVEN_ARTIFACT_ID:="$PACKAGE_NAME"}
: ${JAVA_TEST_OPTS:=""}

MAVEN_OPTS="${MAVEN_OPTS:--Xms2G -Xmx4G}"

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# BUILD TOOL HELPERS
# =============================================================================
_install_maven() {
    if check_command mvn; then
        log_info "Maven already installed: $(mvn --version | head -1)"
        return 0
    fi

    log_info "Installing Maven $MAVEN_VERSION"
    local maven_url="https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

    wget -q "$maven_url" -O /tmp/maven.tar.gz
    sudo tar -xzf /tmp/maven.tar.gz -C /usr/lib/
    rm -f /tmp/maven.tar.gz

    export M2_HOME="/usr/lib/apache-maven-${MAVEN_VERSION}"
    export PATH="${M2_HOME}/bin:$PATH"
}

_install_gradle() {
    if check_command gradle; then
        log_info "Gradle already installed: $(gradle --version | head -1)"
        return 0
    fi

    log_info "Installing Gradle $GRADLE_VERSION"
    local gradle_url="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

    wget -q "$gradle_url" -O /tmp/gradle.zip
    sudo unzip -o -d /opt /tmp/gradle.zip
    rm -f /tmp/gradle.zip

    export GRADLE_HOME="/opt/gradle-${GRADLE_VERSION}"
    export PATH="${GRADLE_HOME}/bin:$PATH"
}

_set_java_home() {
    local version="$1"

    if [[ -z "$JAVA_HOME" ]] || [ ! -x "$JAVA_HOME/bin/java" ]; then

	    unset JAVA_HOME

	    log_info "Detection Java version for $OS_ID"
	    case "$OS_ID" in
		rhel|fedora|centos|ubi)
		    export JAVA_HOME="/usr/lib/jvm/java-${version}-openjdk"
		    ;;
		ubuntu|debian)
		    export JAVA_HOME="/usr/lib/jvm/java-${version}-openjdk-$(dpkg --print-architecture)"
		    ;;
		sles|opensuse*)
		    export JAVA_HOME="/usr/lib64/jvm/java-${version}-openjdk"
		    ;;
	    esac
    fi

    export PATH="$JAVA_HOME/bin:$PATH"
    log_info "Using JDK $version: $(java -version 2>&1 | head -1)"
    $JAVA_HOME/bin/java -version
}

_detect_build_tool() {
    if [[ -f "pom.xml" ]]; then
        echo "maven"
    elif [[ -f "gradlew" ]]; then
        echo "gradle"
    elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "build.xml" ]]; then
        echo "ant"
    elif [[ -f "build.sbt" ]]; then
        echo "sbt"
    else
        echo "maven"  # Default fallback
    fi
}

_try_build_with_jdk() {
    local jdk_version="$1"
    local build_tool="$2"

    log_info "Attempting build with JDK $jdk_version using $build_tool"
    _set_java_home "$jdk_version"

    case "$build_tool" in
        maven)
            mvn -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true
            ;;
        gradle)
            if [[ -f "gradlew" ]]; then
                chmod +x ./gradlew
                ./gradlew -x test
            else
                gradle build -x test
            fi
            ;;
        ant)
            ant build
            ;;
        sbt)
            sbt compile
            ;;
    esac
}

_try_test_with_jdk() {
    local jdk_version="$1"
    local build_tool="$2"

    log_info "Running tests with JDK $jdk_version using $build_tool"
    _set_java_home "$jdk_version"

    case "$build_tool" in
        maven)
            mvn test ${JAVA_TEST_OPTS}
            ;;
        gradle)
            if [[ -f "gradlew" ]]; then
                ./gradlew test ${JAVA_TEST_OPTS}
            else
                gradle test ${JAVA_TEST_OPTS}
            fi
            ;;
        ant)
            ant test ${JAVA_TEST_OPTS}
            ;;
        sbt)
            sbt test ${JAVA_TEST_OPTS}
            ;;
    esac
}

# =============================================================================
# INITIALIZATION
# =============================================================================
detect_os

log_info "======================================================================"
log_info "Building $PACKAGE_NAME version $PACKAGE_VERSION"
log_info "OS: $OS_NAME"
log_info "======================================================================"

# =============================================================================
# CALLBACK: pre_packages (add extra repos before package install)
# =============================================================================
if _has_callback pre_packages; then
    log_info "Running pre_packages hook..."
    pre_packages
fi

# =============================================================================
# INSTALL DEPENDENCIES
# =============================================================================
install_packages

# =============================================================================
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    pre_clone
fi

# =============================================================================
# CLONE REPOSITORY
# =============================================================================
clone_repository

# =============================================================================
# CALLBACK: post_clone (patches, source modifications)
# =============================================================================
if _has_callback post_clone; then
    log_info "Running post_clone hook..."
    post_clone
fi

# =============================================================================
# DETECT AND INSTALL BUILD TOOLS
# =============================================================================
if [[ -z "$BUILD_TOOL" ]]; then
    BUILD_TOOL=$(_detect_build_tool)
fi
log_info "Using build tool: $BUILD_TOOL"

case "$BUILD_TOOL" in
    maven) _install_maven ;;
    gradle) _install_gradle ;;
    sbt) log_info "SBT projects require manual sbt installation" ;;
esac

# =============================================================================
# CALLBACK: pre_build (environment setup)
# =============================================================================
if _has_callback pre_build; then
    log_info "Running pre_build hook..."
    pre_build
fi

# =============================================================================
# BUILD
# =============================================================================
if _has_callback custom_build; then
    log_info "Running custom_build hook..."
    if ! custom_build; then
        report_build_fail
    fi
    SUCCESSFUL_JDK="${JAVA_VERSION:-17}"
elif [[ "$NOARCH" == "true" ]]; then
    # NOARCH: Fetch JAR from Maven Central instead of building
    if [[ -z "$MAVEN_GROUP_ID" ]]; then
        log_error "NOARCH mode requires MAVEN_GROUP_ID to be set"
        report_build_fail
    fi
    local maven_version="${PACKAGE_VERSION#v}"
    local group_path="${MAVEN_GROUP_ID//./\/}"
    local jar_url="https://repo1.maven.org/maven2/${group_path}/${MAVEN_ARTIFACT_ID}/${maven_version}/${MAVEN_ARTIFACT_ID}-${maven_version}.jar"

    log_info "NOARCH mode: Fetching ${MAVEN_GROUP_ID}:${MAVEN_ARTIFACT_ID}:${maven_version} from Maven Central"
    mkdir -p target
    if ! wget -q "$jar_url" -O "target/${MAVEN_ARTIFACT_ID}-${maven_version}.jar"; then
        log_error "Failed to download JAR from: $jar_url"
        report_build_fail
    fi
    log_info "Downloaded: target/${MAVEN_ARTIFACT_ID}-${maven_version}.jar"
    SUCCESSFUL_JDK="${JAVA_VERSION:-17}"
else
    log_info "Building package"

    BUILD_SUCCESS=false
    SUCCESSFUL_JDK=""

    # If JAVA_VERSION is set, only try that version
    if [[ -n "$JAVA_VERSION" ]]; then
        JDK_VERSIONS="$JAVA_VERSION"
    fi

    for jdk in $JDK_VERSIONS; do
        if _try_build_with_jdk "$jdk" "$BUILD_TOOL"; then
            BUILD_SUCCESS=true
            SUCCESSFUL_JDK="$jdk"
            break
        else
            log_warn "Build failed with JDK $jdk, trying next version..."
        fi
    done

    if [[ "$BUILD_SUCCESS" != "true" ]]; then
        report_build_fail
    fi

    log_info "Build succeeded with JDK $SUCCESSFUL_JDK"
fi

# =============================================================================
# CALLBACK: post_build (verification)
# =============================================================================
if _has_callback post_build; then
    log_info "Running post_build hook..."
    post_build
fi

# =============================================================================
# TEST PHASE
# =============================================================================
if [[ "$SKIP_TESTS" == "true" ]]; then
    log_info "Tests skipped (SKIP_TESTS=true)"
    # Container build before exit (report_no_tests exits the script)
    if _should_build_container "${SCRIPT_DIR}"; then
        build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
    fi
    report_no_tests
fi

# =============================================================================
# CALLBACK: pre_test (install test deps or setup environment)
# =============================================================================
if _has_callback pre_test; then
    log_info "Running pre_test hook..."
    if ! pre_test; then
        log_error "pre_test hook failed"
        report_test_fail
    fi
fi

if [[ -n "${JAVA_TEST_OPTS}" ]]; then
    log_info "Running tests with options: ${JAVA_TEST_OPTS}"
else
    log_info "Running tests"
fi

test_status=1

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    _try_test_with_jdk "$SUCCESSFUL_JDK" "$BUILD_TOOL" && test_status=0 || test_status=$?
fi

# =============================================================================
# CALLBACK: post_test
# =============================================================================
if _has_callback post_test; then
    log_info "Running post_test hook..."
    post_test
fi

# =============================================================================
# CONTAINER BUILD (optional)
# =============================================================================
if [[ $test_status -eq 0 ]] && _should_build_container "${SCRIPT_DIR}"; then
    build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
fi

# =============================================================================
# REPORT RESULTS
# =============================================================================
if [[ $test_status -eq 0 ]]; then
    report_build_test_success
else
    report_build_success_test_fail
fi
