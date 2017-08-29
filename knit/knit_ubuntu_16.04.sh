# ----------------------------------------------------------------------------
#
# Package	: knit
# Version	: 0.2.1
# Source repo	: https://github.com/dask/knit
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Update source
sudo apt-get update -y
sudo apt-get install -y git python python-dev python-setuptools \
    build-essential maven openjdk-8-jdk libxml2-dev libxslt-dev zlib1g-dev
sudo easy_install pip
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
sudo pip install pytest-cov tornado toolz distributed numpy

# Clone and build source code.
git clone http://github.com/dask/knit
cd knit
sudo python setup.py install mvn
