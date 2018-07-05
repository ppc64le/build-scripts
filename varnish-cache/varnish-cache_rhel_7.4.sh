# ----------------------------------------------------------------------------
#
# Package	: varnish-cache
# Version	: 6.0.0
# Source repo	: https://github.com/varnishcache/varnish-cache
# Tested on	: rhel_7.4
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
sudo yum update -y
sudo yum groupinstall -y 'Development Tools'
sudo yum install -y git python curl pcre-devel libedit python-docutils \
    ncurses-devel graphviz readline-devel

# Clone and build source.
git clone https://github.com/varnishcache/varnish-cache
cd varnish-cache
./autogen.sh
./configure
make
make test
sudo make install
