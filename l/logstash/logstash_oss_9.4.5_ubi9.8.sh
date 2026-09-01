#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : logstash
# Version        : v9.4.5
# Source repo    : https://github.com/elastic/logstash
# Tested on      : UBI 9.8
# Ci-Check       : True
# Language       : Java, Ruby
# Script License : Apache License, Version 2 or later
# Maintainer     : Prachi Gaonkar <prachi.gaonkar@ibm.com>
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
BUILD_HOME=$(pwd)
REPO_DIR="$BUILD_HOME/$PACKAGE_NAME"
SCRIPT_PATH=$(dirname "$(realpath "$0")")

VERSION="${PACKAGE_VERSION#v}"

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
echo "OS is $OS_NAME"

yum -y update && yum install -y \
    git procps yum-utils wget ncurses make gcc-c++ libffi-devel \
    java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless

# bison and readline-devel are not in UBI9; add CentOS Stream 9 repos
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

cat > /etc/yum.repos.d/cs9-crb.repo << 'EOF'
[cs9-crb]
name=CentOS Stream 9 - CRB
baseurl=https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF

yum install -y bison readline-devel

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

cd "${BUILD_HOME}"

if ! git clone "${PACKAGE_URL}" "${PACKAGE_NAME}"; then
    echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
if ! git apply --ignore-whitespace "${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch"; then
    echo "------------------${PACKAGE_NAME}:patch_fails---------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Patch_Fails"
    exit 1
fi

curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
# RVM only supports installation via its bootstrap script; piping to bash is the upstream-mandated method
curl -L https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version)
source /etc/profile.d/rvm.sh

rvm --version
ruby --version

# Disable JVM TLS session cache to avoid SSLError on ppc64le; unset after the JRuby subshell below.
export JAVA_TOOL_OPTIONS="-Djdk.tls.client.sessionCacheSize=0 -Djdk.tls.useExtendedMasterSecret=false"
gem install rake
gem install bundler

rake --version
bundle -v

export OSS=true
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=$BUILD_HOME/$PACKAGE_NAME
export ARCH=ppc64le
export GRADLE_OPTS="-Djdk.tls.client.sessionCacheSize=0 -Djdk.tls.useExtendedMasterSecret=false"

if ! ./gradlew installDevelopmentGems; then
    echo "------------------${PACKAGE_NAME}:install_dev_gems_fails------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | InstallDevelopmentGems_Fails"
    exit 1
fi
echo "------------------${PACKAGE_NAME}:install_dev_gems_success------------------------------"

if ! ./gradlew installDefaultGems; then
    echo "------------------${PACKAGE_NAME}:install_default_gems_fails-------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | InstallDefaultGems_Fails"
    exit 1
fi
echo "------------------${PACKAGE_NAME}:install_default_gems_success-------------------------"

if ! ./gradlew copyAllJdks; then
    echo "------------------${PACKAGE_NAME}:copy_all_jdks_fails--------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | CopyAllJdks_Fails"
    exit 1
fi
echo "------------------${PACKAGE_NAME}:copy_all_jdks_success--------------------------------"

# Fallback: write JDK_VERSION if copyAllJdks did not produce it
if [ ! -f "$REPO_DIR/JDK_VERSION" ]; then
    JDK_REL="$REPO_DIR/jdk-linux-ppc64le/release"
    if [ ! -f "$JDK_REL" ]; then
        echo "ERROR: JDK_VERSION missing and $JDK_REL not found" >&2
        exit 1
    fi
    grep 'IMPLEMENTOR_VERSION=' "$JDK_REL" | cut -d'"' -f2 > "$REPO_DIR/JDK_VERSION"
fi

if ! ./gradlew assemble; then
    echo "------------------${PACKAGE_NAME}:assemble_fails-------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Assemble_Fails"
    exit 1
fi
echo "------------------${PACKAGE_NAME}:assemble_success-------------------------------------"

# Build OSS tar using vendored JRuby; safe.directory needed for git rev-parse in build metadata
git config --global --add safe.directory "$REPO_DIR"

if ! (
    cd "$REPO_DIR"
    cp Gemfile.jruby-3.4.lock.release Gemfile.lock
    vendor/jruby/bin/jruby -S gem install bundler --no-document
    vendor/jruby/bin/jruby -S bundle install --without development test
    ARCH=ppc64le BUNDLE_WITHOUT='development:test' RELEASE=1 \
        vendor/jruby/bin/jruby -S bundle exec rake artifact:archives_oss
); then
    echo "------------------${PACKAGE_NAME}:oss_tar_build_fails--------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | OssTarBuild_Fails"
    exit 1
fi
echo "------------------${PACKAGE_NAME}:oss_tar_build_success--------------------------------"
echo "OSS tar: $REPO_DIR/build/logstash-oss-${VERSION}-linux-ppc64le.tar.gz"
unset JAVA_TOOL_OPTIONS

# Run tests as non-root
useradd -m -s /bin/bash logstash-test || true
chown -R logstash-test:logstash-test "$REPO_DIR"
export LS_HEAP_SIZE=2048m

if ! su -s /bin/bash logstash-test -c "
    export HOME=/home/logstash-test
    export JAVA_HOME=$JAVA_HOME
    export PATH=$PATH
    export OSS=$OSS
    export LOGSTASH_SOURCE=$LOGSTASH_SOURCE
    export LOGSTASH_PATH=$LOGSTASH_PATH
    export ARCH=$ARCH
    export LS_HEAP_SIZE=$LS_HEAP_SIZE
    export GRADLE_OPTS=\"$GRADLE_OPTS\"
    cd '$REPO_DIR' && ./gradlew test
"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
echo "------------------${PACKAGE_NAME}:test_success-----------------------------------------"

if ! su -s /bin/bash logstash-test -c "
    export HOME=/home/logstash-test
    export JAVA_HOME=$JAVA_HOME
    export PATH=$PATH
    export OSS=$OSS
    export LOGSTASH_SOURCE=$LOGSTASH_SOURCE
    export LOGSTASH_PATH=$LOGSTASH_PATH
    export ARCH=$ARCH
    export LS_HEAP_SIZE=$LS_HEAP_SIZE
    export GRADLE_OPTS=\"$GRADLE_OPTS\"
    cd '$REPO_DIR' && ./gradlew check
"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
echo "------------------${PACKAGE_NAME}:check_success----------------------------------------"
echo "OSS tar available at : $REPO_DIR/build/logstash-oss-${VERSION}-linux-ppc64le.tar.gz"

echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
echo "${PACKAGE_URL} ${PACKAGE_NAME}"
echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
