#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : bokeh
# Version          : 3.1.0
# Source repo      : https://github.com/bokeh/bokeh.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=bokeh
PACKAGE_VERSION=${1:-3.1.0}
PACKAGE_URL=https://github.com/bokeh/bokeh.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip libjpeg-devel nodejs npm

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Install additional dependencies
pip install build Pillow
pip install . 

#install
if ! pyproject-build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
