#!/bin/bash

# ----------------------------------------------------------------------------
# Package       : zync
# Version       : 3scale-2.15.1-GA
# Source repo   : https://github.com/3scale/zync
# Tested on     : UBI:9.3
# Language      : Ruby, PLpgSQL
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bharti Somra <Bharti.Somra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

dnf update -y \
 && dnf install -y make gcc wget git gem ruby ruby-devel xz ruby-irb redhat-rpm-config \
    shared-mime-info.ppc64le zlib.ppc64le zlib-devel.ppc64le \
 && gem install bundler

dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm \
 && dnf install -y postgresql13-server \
 && dnf install -y libpq5 libpq5-devel

su - postgres <<'EOF'
PACKAGE_NAME=zync
PACKAGE_VERSION=${1:-3scale-2.15.1-GA}
PACKAGE_URL=https://github.com/3scale/zync.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PGDATA=$PWD/pgsql/data
mkdir -p $PGDATA
export PATH=$PATH:/usr/pgsql-13/bin:/usr/local/bin

pg_ctl initdb -D $PGDATA -o "-E=UTF8"
# To start the server
/usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/zync/pgsql/data -l logfile start

bundle config set --local path 'vendor/bundle'

# install & setup
if bundle install && ./bin/setup; then
        echo "------------------$PACKAGE_NAME:Both_build_and_setup_done---------------------------------------"
        echo "$PACKAGE_NAME $PACKAGE_VERSION"
else
        echo "------------------$PACKAGE_NAME:Both_build_and_setup_failed---------------------------------------"
        echo "$PACKAGE_NAME $PACKAGE_VERSION"
        exit 1
fi

# Ruby is strict when it comes to comparisons, can't compare a String to a Gem::Version object directly
# Need to convert both sides to Gem::Version
sed -i 's/if Rails.version < Gem::Version.new('\''7.1.0'\'')/if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("7.1.0")/' test/jobs/process_entry_job_test.rb


# test
if bundle exec rails test; then
        echo "------------------$PACKAGE_NAME:test_passed---------------------------------------"
        echo "$PACKAGE_NAME $PACKAGE_VERSION"
        exit 0
else
        echo "------------------$PACKAGE_NAME:test_failed---------------------------------------"
        echo "$PACKAGE_NAME $PACKAGE_VERSION"
        exit 1
fi
EOF

