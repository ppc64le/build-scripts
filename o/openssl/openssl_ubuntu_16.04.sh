# ----------------------------------------------------------------------------
#
# Package	: openssl
# Version	: 1.1.1-dev
# Source repo	: https://github.com/openssl/openssl
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

sudo apt-get update -y

sudo apt-get install -y git build-essential

git clone https://github.com/openssl/openssl
cd openssl
./config
make 
make test
