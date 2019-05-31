# ----------------------------------------------------------------------------
#
# Package	: fluentd
# Version	: v1.4.2 
# Source repo	: https://github.com/fluent/fluentd
# Tested on	: RHEL 7.6
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Ghatwal <ghatwala@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies.
sudo yum update -y
sudo yum install -y git ruby-devel.ppc64le ruby gnupg2 curl which 

# Install ruby and rvm.
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -L https://get.rvm.io | bash -s stable
#source ~/.rvm/scripts/rvm
source /etc/profile.d/rvm.sh
rvm install 2.6.3
rvm use 2.6.3 --default
ruby -v
gem install bundler

# Clone and build source.
git clone https://github.com/fluent/fluentd && cd fluentd && git checkout v1.4.2
bundle install --path=./vendor/bundle && gem install fluentd
fluentd --version
