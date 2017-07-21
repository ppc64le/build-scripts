# ----------------------------------------------------------------------------
#
# Package       : R lang
# Version       : 3.4.1
# Source repo   : https://cloud.r-project.org/src/base/R-3/R-3.4.1.tar.gz
# Tested on     : Ubuntu_16.04
# Script License:  Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#! /bin/bash 
sudo apt-get update

#Install Dependencies
sudo apt-get install -y wget tar gcc g++ make gfortran build-essential libreadline6 libreadline6-dev xorg-dev \
            libbz2-ocaml-dev liblzma-dev libghc-pcre-light-dev libcurl4-openssl-dev

# Download and extract source code
wget https://cloud.r-project.org/src/base/R-3/R-3.4.1.tar.gz
tar -xvzf R-3.4.1.tar.gz && cd R-3.4.1

## Build and Test
./configure LIBnn=lib
make && sudo make install
sudo touch /etc/default/locale && \
    echo "LC_CTYPE=\"en_GB.UTF-8\"" >> sudo /etc/default/locale && \
    echo "LC_ALL=\"en_GB.UTF-8\"" >> sudo /etc/default/locale && \
    echo "LANG=\"en_GB.UTF-8\"" >> sudo /etc/default/locale && \
    sudo locale-gen en_GB en_GB.UTF-8 && \
    sudo dpkg-reconfigure --frontend=noninteractive locales
make check
