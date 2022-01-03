# ----------------------------------------------------------------------------
#
# Package       : asttokens
# Version       : v2.0.5
# Source repo   : https://github.com/gristlabs/asttokens
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -eu

export ASTTOKENS_SLOW_TESTS=1
VERSION="${1:-v2.0.5}"

if [ -d "asttokens" ] ; then
  rm -rf asttokens
fi

# Dependency installation
sudo dnf install -y python39 git wget gcc python39-devel

# Download the repos
git clone https://github.com/gristlabs/asttokens

# Build and Test asttokens
cd asttokens
git checkout $VERSION

pip3 install --upgrade setuptools>=44 wheel setuptools_scm[toml]>=3.4.3 pep517
pip3 install --upgrade coveralls

python3 ./setup.py bdist_wheel
export WHLNAME=./dist/asttokens-0.CI-py2.py3-none-any.whl
mv ./dist/*.whl $WHLNAME
sudo pip3 install --upgrade --pre "$WHLNAME[test]"
coverage run --branch --include='asttokens/*' -m pytest --junitxml=./rspec.xml
