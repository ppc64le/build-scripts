# ----------------------------------------------------------------------------
#
# Package	: google-ngrams
# Version	: 4.0.1
# Source repo	: https://github.com/dimazest/google-ngram-downloader
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
sudo apt-get install -y git python python-setuptools tox

git clone https://github.com/dimazest/google-ngram-downloader
cd google-ngram-downloader
python setup.py build
python setup.py install
tox -e py27-with-doctest
