# ----------------------------------------------------------------------------
# Package       : 3scale_toolbox 
# Version       : v0.18.1
# Source repo   : https://github.com/3scale/3scale_toolbox
# Tested on     : RHEL_8.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


#!/bin/bash

# pre-reqs
yum install -y gem redhat-rpm-config ruby-devel zlib-devel.ppc64le git make cmake 
yum install -y zlib-devel.ppc64le gcc.ppc64le gcc-c++.ppc64le

# clone and checkout last stable release
git clone https://github.com/3scale/3scale_toolbox
cd 3scale_toolbox

RELEASE_TAG=v0.18.1
git checkout $RELEASE_TAG

# Install bundle & racc
gem install bundler:2.1.4
gem install racc

# vendor/bundle install
bundle install --jobs=3 --retry=3 --path vendor/bundle

# Rake install
bundle exec rake install

# Unit-tests
bundle exec rake spec:unit

# Populate .env for Integration tests
cat >> .env << EOF
ENDPOINT=https://autotest-admin.3scale.net/
PROVIDER_KEY=dc6ecfa9d8eb9658a2082ef796d6cee4299fd1b57fe605d5fa5082722961c9dd
VERIFY_SSL=false
EOF

# Trigger Integration Tests
bundle exec rake spec:integration
