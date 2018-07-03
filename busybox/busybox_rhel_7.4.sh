# ----------------------------------------------------------------------------
#
# Package	: busybox
# Version	: 1.30.0
# Source repo	: http://git.busybox.net/busybox
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
sudo yum install -y git gcc make zip

# Clone and build source.
git clone http://git.busybox.net/busybox
cd busybox
sudo make CONFIG_PREFIX=/ install
make test
