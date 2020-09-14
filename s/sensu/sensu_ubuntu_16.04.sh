# ----------------------------------------------------------------------------
#
# Package	: sensu
# Version	: 1.4.2
# Source repo	: https://github.com/sensu/sensu.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
sudo apt-get update -y
sudo apt-get install -y build-essential ruby-dev libffi-dev ruby erlang-nox \
    sudo libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev redis-server rabbitmq-server git

# Clone source and build.
git clone https://github.com/sensu/sensu.git
cd sensu
sudo service rabbitmq-server start
sudo service redis-server start
sudo gem update --system
sudo gem install bundler
sudo mkdir -p /usr/share/rubygems-integration/all/gems/rake-10.5.0/bin
sudo ln -s /usr/bin/rake /usr/share/rubygems-integration/all/gems/rake-10.5.0/bin/rake
bundle install --jobs=3 --retry=3
bundle exec rake
