# ----------------------------------------------------------------------------
#
# Package	: collectd
# Version	: 5.8.0
# Source repo	: git://github.com/collectd/collectd.git
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

sudo yum update -y
sudo yum group install -y 'Development Tools'
sudo yum install -y git which

git clone git://github.com/collectd/collectd.git
cd collectd
./build.sh
