#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : prometheus/alertmanager
# Version       : 0.9.1
# Source repo   : https://github.com/prometheus/alertmanager
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later 
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

sudo apt-get update 
sudo apt-get install wget git gcc make tar -y

#Install Go
wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz
sudo tar -C /usr/local -zxvf go1.9.1.linux-ppc64le.tar.gz

#Set the PATHs
mkdir $HOME/alertmanager
cd $HOME/alertmanager/
export GOPATH=`pwd`
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

#Clone the source
mkdir -p $GOPATH/src/github.com/prometheus
cd $GOPATH/src/github.com/prometheus
git clone https://github.com/prometheus/alertmanager
cd alertmanager

#Build and test
make build
make test
