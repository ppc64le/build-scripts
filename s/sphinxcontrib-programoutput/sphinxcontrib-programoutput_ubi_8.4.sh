# -----------------------------------------------------------------------------
#
# Package       : sphinxcontrib-programoutput
# Version       : 0.17
# Source repo   : https://github.com/NextThought/sphinxcontrib-programoutput.git
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=sphinxcontrib-programoutput
PACKAGE_VERSION=${1:-0.17}
PACKAGE_URL=https://github.com/NextThought/sphinxcontrib-programoutput.git

yum -y update && yum install -y python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

cd $HOME
git clone ${PACKAGE_URL}
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 setup.py test