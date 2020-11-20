# ----------------------------------------------------------------------------
#
# Package       : Quartz-Scheduler
# Version       : 2.3.1
# Source repo   : https://github.com/quartz-scheduler/quartz
# Tested on     : ubuntu_18.04
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

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk git maven subversion

# Download source
git clone https://github.com/quartz-scheduler/quartz
cd quartz

# Build and Test
./mvnw clean install 
