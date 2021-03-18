# ----------------------------------------------------------------------------
#
# Package       : statsd-c-client
# Version       : master
# Source repo   : https://github.com/romanbsd/statsd-c-client/
# Tested on     : rhel_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
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
sudo yum install -y git gcc-c++ make
git clone https://github.com/romanbsd/statsd-c-client/
cd statsd-c-client
make
