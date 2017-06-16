# ----------------------------------------------------------------------------
#
# Package	: mongo-ruby-driver
# Version	: 2.4.2
# Source repo	: https://github.com/mongodb/mongo-ruby-driver.git
# Tested on	: rhel_7.3
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
sudo yum install -y ruby ruby-devel make gcc gcc-c++ git

# Clone and build source code.
git clone https://github.com/mongodb/mongo-ruby-driver.git
cd mongo-ruby-driver
sudo gem install mongo -v '2.2.4'
