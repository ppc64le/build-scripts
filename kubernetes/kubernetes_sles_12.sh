#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : kubernetes 
# Version       : master 
# Source repo   : https://github.com/kubernetes/kubernetes
# Tested on     : SLES 12
# Script License: Apache License, Version 2 or later 
# Maintainer    : Vaibhav Sood <vaibhavs@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------- 

sudo zypper update 
sudo zypper install -y wget tar make

##Install Go 1.9.2

wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.9.2.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go

##Build kubernetes

go get -d k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
make
