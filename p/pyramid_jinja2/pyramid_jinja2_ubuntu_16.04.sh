# ----------------------------------------------------------------------------
#
# Package	: pyramid_jinja2
# Version	: 2.7
# Source repo	: https://github.com/Pylons/pyramid_jinja2
# Tested on	: ubuntu_16.04
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
sudo apt-get -y update
sudo apt-get install -y git python-setuptools python-dev

# Clone and build source code.
git clone https://github.com/Pylons/pyramid_jinja2
cd pyramid_jinja2
sudo python setup.py install
sudo python setup.py test
