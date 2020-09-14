# ----------------------------------------------------------------------------
#
# Package	: iconv
# Version	: 1.15
# Source repo	: git://git.savannah.gnu.org/libiconv.git
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

sudo apt-get update -y
sudo apt-get install -y git gcc make automake gperf groff gettext

sudo ln -s /usr/bin/aclocal /usr/bin/aclocal-1.12
sudo ln -s /usr/bin/autoconf /usr/bin/autoconf-2.69
sudo ln -s /usr/bin/autoheader /usr/bin/autoheader-2.69
sudo ln -s /usr/bin/automake /usr/bin/automake-1.12

git clone git://git.savannah.gnu.org/libiconv.git
cd libiconv
sed -i 's/GETTEXT_MACRO_VERSION = 0.18/GETTEXT_MACRO_VERSION = 0.19/' po/Makefile.in.in
mkdir -p libcharset/autoconf
./autogen.sh
automake --add-missing
./autogen.sh
./configure --build=ppc64le
sudo make
sudo make install
