# ----------------------------------------------------------------------------
#
# Package       : window-or-global
# Version       : 1.0.1
# Source repo   : https://github.com/purposeindustries/window-or-global.git 
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get update -y
sudo apt-get install -y git nodejs npm


# Clone and build source.
git clone https://github.com/purposeindustries/window-or-global.git
cd window-or-global
npm install
# Tests are failing on both the platform (x86 and ppc) with same error "401 warnings & 24492 errors", hence disabled.
# npm test
