# ----------------------------------------------------------------------------
#
# Package       : zkperl
# Version       : 0.41
# Source repo   : 
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get install -y libzookeeper-mt-dev  libzookeeper-mt2 zookeeper perl-doc cpanminus npm

# Install Zkperl (Zookeeper perl)
sudo cpanm Net::ZooKeeper


# How do I find this module is installed on my system?
# cpan -l | grep "Net::ZooKeeper"

# Where this has installed?
#  perldoc -l Net::ZooKeeper
#  o/p : /usr/local/lib/powerpc64le-linux-gnu/perl/5.22.1/Net/ZooKeeper.pm
