# ----------------------------------------------------------------------------
#
# Package       : snakebite
# Version       : 2.11.0
# Source repo   : https://github.com/spotify/snakebite
# Tested on     : ubuntu_16.04 (python27)
# Script License: Apache License
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Update source and Install dependencies
sudo apt-get update -y
sudo apt-get install -y git python python-setuptools curl openjdk-8-jdk

sudo easy_install pip

#Setting JAVA_HOME for test user in /etc/environment file
echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/" | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

git clone https://github.com/spotify/snakebite
cd snakebite
sudo pip install -r requirements-dev.txt

## Build and Install && Test
python setup.py build && sudo python setup.py install
export USER=root
export TOX_ENV=py27-cdh && sudo python setup.py test --tox-args="-e $TOX_ENV"
export TOX_ENV=py27-hdp && sudo python setup.py test --tox-args="-e $TOX_ENV"
