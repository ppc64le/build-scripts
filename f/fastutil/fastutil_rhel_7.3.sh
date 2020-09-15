# ----------------------------------------------------------------------------
#
# Package       : fastutil
# Version       : 8.1.1
# Source repo   : https://github.com/vigna/fastutil
# Tested on     : rhel_7.3
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

sudo yum update -y && \
        sudo yum install -y git make ant gcc-c++ java-1.8.0-openjdk-devel
        git clone https://github.com/vigna/fastutil
cd fastutil
make sources TEST=1
ant jar javadoc
