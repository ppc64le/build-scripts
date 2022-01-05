# ----------------------------------------------------------------------------
#
# Package        : st2
# Version        : commit #963f97f
# Source repo    : https://github.com/StackStorm/st2
# Tested on      : UBI 8.2
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eux

CWD=`pwd`

sudo su <<RTD

dnf -y --disableplugin=subscription-manager install \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8.2-2.2004.0.2.el8.noarch.rpm \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-repos-8.2-2.2004.0.2.el8.ppc64le.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# Install dependencies
yum install -y python3-pip python3-virtualenv python3-tox gcc-c++ git screen icu libicu libicu-devel openssl-devel make libffi-devel libyaml openldap-devel

cat > /etc/yum.repos.d/mongodb-enterprise-4.4.repo <<'EOF'
[mongodb-enterprise-4.4]
name=MongoDB Enterprise Repository
baseurl=https://repo.mongodb.com/yum/redhat/\$releasever/mongodb-enterprise/4.4/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

yum install -y mongodb-enterprise
systemctl enable mongod
systemctl restart mongod

yum install erlang -y
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc

cat > /etc/yum.repos.d/rabbitmq.repo <<EOF
[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.8.x/el/8/
gpgcheck=0
repo_gpgcheck=0
enabled=1
EOF

yum install -y rabbitmq-server.noarch
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

RTD

git clone https://github.com/StackStorm/st2.git
cd st2
git checkout 963f97f
git submodule update --init --recursive
make all
set +u
source virtualenv/bin/activate
set -u
make cli
echo "Build and test execution finished!"

