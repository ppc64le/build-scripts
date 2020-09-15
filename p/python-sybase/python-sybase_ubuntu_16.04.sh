# ----------------------------------------------------------------------------
#
# Package       : python-sybase
# Version       : 0.40pre2
# Source repo   : https://github.com/fbessho/python-sybase
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Install dependencies.
sudo apt-get update -y && \
sudo apt-get install -y gcc freetds-dev freetds-bin git && \

# Clone and build source.
git clone https://github.com/fbessho/python-sybase
cd $PWD/python-sybase && \
sudo -E SYBASE=/usr bash -l -c "python setup.py build_ext -D HAVE_FREETDS -U WANT_BULKCOPY"
sudo -E SYBASE=/usr bash -l -c "python setup.py install && python setup.py test"
