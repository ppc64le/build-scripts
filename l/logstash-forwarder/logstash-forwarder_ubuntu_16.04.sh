# ----------------------------------------------------------------------------
#
# Package	: logstash-forwarder
# Version	: 0.4.0
# Source repo	: https://github.com/elastic/logstash-forwarder.git
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

# Install Dependencies.
sudo apt-get update -y
sudo apt-get install -y ruby ruby-dev make libffi-dev gcc golang-go \
  curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev \
  libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  libffi-dev git

# Set gccgo bin and lib paths.
export PATH=$PATH:/usr/local/gccgo/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gccgo/lib64

# Build Logstash-Forwarder.
git clone https://github.com/elastic/logstash-forwarder.git
cd logstash-forwarder
go build -gccgoflags '-static-libgo' -o logstash-forwarder

# Make native packages of logstash-forwarder.
sudo gem install bundler && sudo bundle install
sudo make deb
