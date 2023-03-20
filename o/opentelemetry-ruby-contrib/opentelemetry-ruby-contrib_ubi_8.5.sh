#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-ruby-contrib
# Version	:  opentelemetry-instrumentation-aws_sdk/v0.3.1
# Source repo	: https://github.com/open-telemetry/opentelemetry-ruby-contrib
# Tested on	: ubi 8.5
# Language      : ruby
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# notes: start the  container with following command:
# docker run --privileged -dit registry.access.redhat.com/ubi8/ubi                                                       :8.5 /usr/sbin/init 
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-ruby-contrib"
PACKAGE_VERSION=${1:-"opentelemetry-instrumentation-aws_sdk/v0.3.1"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-ruby-contrib"
HOME_DIR=$PWD

echo "Installing required repos..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf install -qy epel-release
dnf config-manager --enable powertools

echo "installing required pkgs..."
dnf module install -qy ruby:3.0
dnf install -qy git gcc-c++ ruby-devel make gcc-c++ libsqlite3x-devel procps epel-release java-1.8.0-openjdk-devel wget
dnf module install -qy mysql
dnf module install -qy postgresql:13
dnf install -qy postgresql-devel mysql-devel rubygem-irb
dnf install -qy docker-ce docker-compose-plugin

install_test_gem() {
    if [ -f "./Appraisals" ]; then
        if (bundle install &>/dev/null && bundle exec appraisal install &>/dev/null); then
            echo "installation successful for $(basename "$PWD")"
        else
            echo "installation failed for $(basename "$PWD")"
            return 1
        fi
    elif [ -f "./Gemfile" ]; then
        if bundle install &>/dev/null; then
            echo "installation successful for $(basename "$PWD")"
        else
            echo "installation failed for $(basename "$PWD")"
            return 1
        fi
    else
        echo "can't find Gem in $(basename "$PWD")"
        return 1
    fi
    if [ -f "./Appraisals" ]; then
        if bundle exec appraisal rake test &>/dev/null; then
            echo "Tests successful for $(basename "$PWD")"
        else
            echo " tests failed for $(basename "$PWD")"
        fi
    elif [ -f "./Rakefile" ]; then
        if bundle exec rake test &>/dev/null; then
            echo "Tests successful for $(basename "$PWD")"
        else
            echo " tests failed for $(basename "$PWD")"
        fi
    else
        echo "No rake tests found!"
    fi
}

export -f install_test_gem

cd /opt
wget -q https://downloads.apache.org/kafka/3.2.3/kafka_2.12-3.2.3.tgz
tar xf kafka_2.12-3.2.3.tgz
cd /opt/kafka_2.12-3.2.3
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
echo "listeners=PLAINTEXT://localhost:29092" >>config/server.properties
bin/kafka-server-start.sh config/server.properties &

cd "$HOME_DIR"
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
git apply "$HOME_DIR"/patch-ot
systemctl start docker
docker compose build 
docker compose up -d

cd ./instrumentation/
find "$PWD" -maxdepth 1 -type d -exec sh -c 'cd  $1 && install_test_gem' _ {} \;
cd ../propagator/
find "$PWD" -maxdepth 1 -type d -exec sh -c 'cd  $1 && install_test_gem' _ {} \;
cd ../resource_detectors/
install_test_gem
