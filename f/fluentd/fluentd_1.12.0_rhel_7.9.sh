# ----------------------------------------------------------------------------
#
# Package	: fluentd
# Version	: v1.12.0 
# Source repo	: https://github.com/fluent/fluentd
# Tested on	: RHEL 7.9
# Script License: Apache License, Version 2 or later
# Maintainer	: Swati Singhal <swati.singhal@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies.
yum update -y
yum install -y git ruby-devel.ppc64le ruby gnupg2 curl which 

# importing gpg keys from rvm.io 
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

# Install ruby and rvm.
curl -L https://get.rvm.io | bash -s stable

source /etc/profile.d/rvm.sh
#####################
# Observed a test failure with 2.7, continue with 2.6 or 2.5
#####################
rvm install 2.6.3
rvm use 2.6.3 --default
ruby -v
gem install bundler


# Clone and build source.
git clone https://github.com/fluent/fluentd && cd fluentd && git checkout v1.12.0
bundle install --path=./vendor/bundle && gem install fluentd
fluentd --version

# Execute tests
bundle exec rake test

#Defining colors for showing message
NC='\033[0m'
RED='\033[0;31m'
BLUE='\033[0;34m'

echo -e "${BLUE}
--------------------------------------------------------------
${NC}Following test failures also observed on ${BLUE}X86 Architecture:
- ${RED}test: can execute external command just once, and can terminate it forcedly when shutdown/terminate even if it ignore SIGTERM${BLUE}
- ${RED}test: invalid values are set to RUBYOPT(TestFluentdCommand::configured to run 2 workers)${BLUE}
--------------------------------------------------------------
${NC}"RG SLIRP=https://rpmfind.net/linux/opensuse/ports/ppc/distribution/leap/15.2/repo/oss/ppc64le/slirp4netns-0.3.0-lp152.1.3.ppc64le.rpm

