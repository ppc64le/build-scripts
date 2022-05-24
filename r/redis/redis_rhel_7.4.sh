# ----------------------------------------------------------------------------
#
# Package	: redis
# Version	: 3.2.9
# Source repo	: https://github.com/antirez/redis.git
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
sudo yum install -y git tcl
sudo yum group install -y 'Development Tools'

# Clone and build source.
git clone https://github.com/antirez/redis.git
cd redis
make V=1 MALLOC=libc
sudo make install
