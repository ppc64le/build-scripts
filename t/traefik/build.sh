#----------------------------------------------------------------------------
#
# Package         : traefik/traefik-library-image
# Version         : master
# Source repo     : https://github.com/traefik/traefik-library-image.git
# Tested on       : rhel_7.8
# Script License  : Apache License, Version 2.0
# Maintainer      : Bivas Das <bivasda1@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------
# Prerequisites:
#
# docker must be installed and running.
#
#
# ----------------------------------------------------------------------------
VERSION=master
set -e
yum update -y
yum install git -y
git clone https://github.com/traefik/traefik-library-image.git
cd traefik-library-image
git checkout $VERSION
wget https://raw.githubusercontent.com/traefik/traefik/master/traefik.sample.toml
mv traefik.sample.toml traefik.toml
chmod 755 traefik.toml
mv -f ../Dockerfile alpine
# Building Image
cd alpine
docker build -t traefik-library-image:latest -f Dockerfile .
#Run Image
#docker run -itd traefik-library-image:latest bash
