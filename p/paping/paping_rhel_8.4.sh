ckage       : paping
# Version       : v1.5.5
# Source repo   : https://github.com/koolhazz/paping.git
# Tested on     : RHEL 8.4
# Script License: MIT License
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=paping
PACKAGE_VERSION=v1.5.5
PACKAGE_URL=https://github.com/koolhazz/paping.git
dnf install git make gcc-c++ -y
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ../paping_ppc64le.patch
make ppc64le
paping www.google.com -p 80 -c 4
