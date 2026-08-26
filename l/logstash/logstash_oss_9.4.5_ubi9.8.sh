#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : logstash
# Version        : v9.4.5
# Source repo    : https://github.com/elastic/logstash
# Tested on      : UBI 9.8
# Ci-Check       : True
# Language       : Java, Ruby
# Script License: Apache License Version 2.0
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=v9.4.5
PACKAGE_NAME=logstash
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/elastic/logstash
WORKDIR=$(pwd)
REPO_DIR="$WORKDIR/$PACKAGE_NAME"
SCRIPT_PATH=$(dirname $(realpath $0))


# Strip the leading 'v' to get the bare semver used in artifact filenames.
VERSION="${PACKAGE_VERSION#v}"

OS_VERSION=$(grep ^VERSION_ID /etc/os-release | cut -d= -f2 | cut -d\" -f2)
echo "RHEL VERSION is $OS_VERSION"

# ── 1. System dependencies ────────────────────────────────────────────────────
yum -y update && yum install -y \
    git procps yum-utils wget ncurses make gcc-c++ libffi-devel \
    java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless

# bison and readline-devel are not in UBI9; pull from the official CentOS Stream 9 mirrors
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official

cat > /etc/yum.repos.d/cs9-appstream.repo << 'EOF'
[cs9-appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF

cat > /etc/yum.repos.d/cs9-baseos.repo << 'EOF'
[cs9-baseos]
name=CentOS Stream 9 - BaseOS
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF

yum install -y bison readline-devel

# ── 2. Java environment ───────────────────────────────────────────────────────
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# ── 3. Clone and checkout ─────────────────────────────────────────────────────
cd "${WORKDIR}"

if ! git clone "${PACKAGE_URL}" "${PACKAGE_NAME}"; then
    echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# ── 3a. Apply ppc64le arch patch ──────────────────────────────────────────────
# Patches four files upstream doesn't support out of the box on ppc64le:
#
#   build.gradle        – selectArch(): both the ARCH env-var branch and the
#                         os.arch switch need "ppc64le" cases, otherwise Gradle
#                         falls through to "arm64" and downloads an aarch64 JDK.
#
#   rakelib/artifacts.rake – ARCH constant: add "ppc64le"/"ppc64" branch so Rake
#                         artifact tasks resolve the correct arch string.
#                         prepare/prepare-oss tasks: add ppc64le branch so only
#                         linux packages are built (no windows/darwin on ppc64le).
#
#   logstash-core/lib/logstash/agent.rb
#                       – initialize_geoip_database_metrics rescues only LoadError;
#                         with OSS=true the xpack GeoIP settings are never registered
#                         so Manager.instance throws ArgumentError instead — adding
#                         ArgumentError to the rescue clause silences it correctly.
#
#   logstash-core/spec/logstash/api/commands/default_metadata_spec.rb
#                       – two monitoring-section tests call set_value on
#                         xpack.monitoring.* settings that are never registered
#                         with OSS=true; guard each with a registered? skip so
#                         they are skipped rather than erroring in OSS mode.

git apply --ignore-whitespace  "${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch"

# ── 4. Install RVM and Ruby (version pinned by .ruby-version in the repo) ─────
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version)
source /etc/profile.d/rvm.sh

rvm --version
ruby --version

# ── 5. Install rake and bundler ───────────────────────────────────────────────
gem install rake
gem install bundler

rake --version
bundle -v

# ── 6. Build: install OSS dependencies via Gradle ────────────────────────────
# OSS=true tells Gradle/Rake to strip x-pack plugins.
# ARCH=ppc64le ensures selectArch() and the rake ARCH constant resolve correctly
export OSS=true
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=$WORKDIR/$PACKAGE_NAME
export ARCH=ppc64le

if ! ./gradlew installDevelopmentGems; then
    echo "FAILED: installDevelopmentGems"
    exit 1
fi
echo "SUCCESS: installDevelopmentGems"

if ! ./gradlew installDefaultGems; then
    echo "FAILED: installDefaultGems"
    exit 1
fi
echo "SUCCESS: installDefaultGems"

# copyAllJdks downloads the ppc64le Temurin JDK into jdk-linux-ppc64le/ and
# writes JDK_VERSION — both are required by artifact:archives_oss at tar time.
if ! ./gradlew copyAllJdks; then
    echo "FAILED: copyAllJdks"
    exit 1
fi
echo "SUCCESS: copyAllJdks"

# Fallback: write JDK_VERSION if copyAllJdks doLast block did not produce it.
# Both JDK_VERSION and jdk-linux-ppc64le/ are written inside the cloned repo dir.
if [ ! -f "$REPO_DIR/JDK_VERSION" ]; then
    JDK_REL="$REPO_DIR/jdk-linux-ppc64le/release"
    if [ ! -f "$JDK_REL" ]; then
        echo "ERROR: JDK_VERSION missing and $JDK_REL not found" >&2
        exit 1
    fi
    grep 'IMPLEMENTOR_VERSION=' "$JDK_REL" | cut -d'"' -f2 > "$REPO_DIR/JDK_VERSION"
fi

if ! ./gradlew assemble; then
    echo "FAILED: assemble"
    exit 1
fi
echo "SUCCESS: assemble"

# ── 7. Build the OSS tar ──────────────────────────────────────────────────────
# Run as root before the test-user chown, so no ownership restore is needed.
# git safe.directory lets generate_build_metadata call git rev-parse HEAD.
# OSS=true strips x-pack plugins; RELEASE=1 removes the -SNAPSHOT suffix.
# Source RVM so the Ruby/rake version pinned in Gemfile.lock is on PATH, then
# use `bundle exec rake` to satisfy the exact rake version required by the project.
git config --global --add safe.directory "$REPO_DIR"
source /etc/profile.d/rvm.sh

echo "--- Building OSS tar (artifact:archives_oss) ---"
if ! ( cd "$REPO_DIR" && OSS=true ARCH=ppc64le RELEASE=1 bundle exec rake artifact:archives_oss ); then
    echo "FAILED: rake artifact:archives_oss"
    exit 1
fi
echo "SUCCESS: OSS tar at $REPO_DIR/build/logstash-oss-${VERSION}-linux-ppc64le.tar.gz"

# ── 8. Run unit and integration tests as non-root ────────────────────────────
# ./gradlew test  — unit tests: logstash-core:javaTests (JUnit) +
#                               logstash-core:rubyTests (RSpec via JRuby)
# ./gradlew check — everything in test + additional quality/consistency checks
#
# Note: runIntegrationTests (qa/integration/) requires a live Elasticsearch and
# Filebeat (copyEs, copyFilebeat dependencies) so it cannot run here.
# check.dependsOn runIntegrationTests is intentionally commented out upstream.
#
# Tests run as a dedicated non-root user. WritableDirectorySetting tests use
# File.chmod to create non-writable directories and expect validation to fail —
# root bypasses filesystem permission checks so those tests always fail as root.
# 'su -s /bin/bash' with explicitly exported HOME avoids the HOME=/root issue
# that previously caused agent/metrics spec hooks to crash.
useradd -m -s /bin/bash logstash-test || true
chown -R logstash-test:logstash-test "$REPO_DIR"
export LS_HEAP_SIZE=2048m

echo "--- Running unit tests (gradlew test) ---"
if ! su -s /bin/bash logstash-test -c "
    export HOME=/home/logstash-test
    export JAVA_HOME=$JAVA_HOME
    export PATH=$PATH
    export OSS=$OSS
    export LOGSTASH_SOURCE=$LOGSTASH_SOURCE
    export LOGSTASH_PATH=$LOGSTASH_PATH
    export ARCH=$ARCH
    export LS_HEAP_SIZE=$LS_HEAP_SIZE
    cd "$REPO_DIR" && ./gradlew test
"; then
    echo "FAILED: unit tests"
    exit 2
fi
echo "SUCCESS: unit tests"

echo "--- Running check (gradlew check) ---"
if ! su -s /bin/bash logstash-test -c "
    export HOME=/home/logstash-test
    export JAVA_HOME=$JAVA_HOME
    export PATH=$PATH
    export OSS=$OSS
    export LOGSTASH_SOURCE=$LOGSTASH_SOURCE
    export LOGSTASH_PATH=$LOGSTASH_PATH
    export ARCH=$ARCH
    export LS_HEAP_SIZE=$LS_HEAP_SIZE
    cd "$REPO_DIR" && ./gradlew check
"; then
    echo "FAILED: check"
    exit 2
fi
echo "SUCCESS: check"
