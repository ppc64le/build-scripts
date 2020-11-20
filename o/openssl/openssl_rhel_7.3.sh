# ----------------------------------------------------------------------------
#
# Package	: openssl
# Version	: 1.1.1-dev
# Source repo	: https://github.com/openssl/openssl
# Tested on	: rhel_7.3
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

sudo yum update -y

sudo yum groupinstall 'Development Tools' -y

sudo yum install -y git perl-core

git clone https://github.com/openssl/openssl
cd openssl
./config
make 
make test
