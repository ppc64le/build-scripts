# -----------------------------------------------------------------------------
#
# Package	: erubi
# Version	: v1.10.0
# Source repo	: https://github.com/jeremyevans/erubi
# Tested on	: UBI 8.4
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=erubi
PACKAGE_VERSION=${1:-1.10.0}
PACKAGE_URL=https://github.com/jeremyevans/erubi

yum install -y gcc git make ruby ruby-devel redhat-rpm-config

gem install bundle
gem install rake

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

bundle install --gemfile=.travis.gemfile

bundle exec  --gemfile=.travis.gemfile rake

exit 0
