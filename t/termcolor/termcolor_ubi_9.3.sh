#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : termcolor
# Version        : 1.1.0
# Source repo    : https://github.com/termcolor/termcolor.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek sharma<vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested on the specified platform using the
#             mentioned version of the package. It may not work as expected
#             with newer versions of the package and/or distribution. In such
#             cases, please contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=termcolor
PACKAGE_VERSION=1.1.0
PACKAGE_URL=https://github.com/termcolor/termcolor.git

# Install necessary system packages
yum install -y git gcc gcc-c++ make wget sudo openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel
yum install -y pip

# Upgrade pip and install necessary Python packages
pip install --upgrade pip setuptools wheel greenlet pytest


# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Set up a virtual environment
python3 -m venv env
source env/bin/activate

# Upgrade pip within the virtual environment
pip install --upgrade pip

# Install the package
pip install .

# Skip all tests
echo "Skipping all test cases as per the requirement."

# Deactivate the virtual environment
deactivate

echo "Build and installation completed successfully, No tests are there."
