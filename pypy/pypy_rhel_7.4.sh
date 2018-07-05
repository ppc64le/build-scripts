# ----------------------------------------------------------------------------
#
# Package	: pypy
# Version	: 6.0
# Source repo	: https://bitbucket.org/pypy/pypy
# Tested on	: rhel_7.4
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
sudo yum update -y
sudo yum install -y mercurial gcc make libffi-devel pkgconfig zlib-devel \
    bzip2-devel sqlite-devel ncurses-devel expat-devel openssl-devel \
    tk-devel gdbm-devel python-cffi
# xz-devel  # For lzma on PyPy3

# Clone and build source.
hg clone https://bitbucket.org/pypy/pypy
cd pypy/pypy/goal
python ../../rpython/bin/rpython --opt=jit
