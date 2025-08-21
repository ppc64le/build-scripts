# ----------------------------------------------------------------------------
#
# Package	: pytest-mock
# Version	: 3.14.1
# Source repo	: https://github.com/pytest-dev/pytest-mock
# Tested on	: ubi_9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Rosman Cariño <rcarino@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -e

dnf install -y git gcc-toolset-13 python3 python3-devel python3-pip

source /opt/rh/gcc-toolset-13/enable

python3 -m pip install --upgrade pip setuptools wheel build twine

git clone https://github.com/pytest-dev/pytest-mock
cd pytest-mock

python3 -m build
twine check dist/*
