# ----------------------------------------------------------------------------
#
# Package	: smhasher
# Version	: Not available.
# Source repo	: https://github.com/aappleby/smhasher
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

# Note:
# The original repository is: https://github.com/aappleby/smhasher
# However this seems to be dormant for a long time. Till the ppc64le specific
# fixes are merged with original repository, it is advised to use alternate
# repository: https://github.com/asowani/smhasher

sudo yum update -y
sudo yum install git gcc-c++ which make cmake

#git clone https://github.com/aappleby/smhasher
git clone https://github.com/asowani/smhasher
cd smhasher/src
cmake .
make
./SMHasher murmur2
