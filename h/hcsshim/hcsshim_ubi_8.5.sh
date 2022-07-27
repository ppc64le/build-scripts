#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: "hcsshim"
# Version	: master (0b7e02b)
# Source repo	: https://github.com/microsoft/hcsshim
# Tested on	: ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


sudo docker run -e COUCHDB_USER=currency -e COUCHDB_PASSWORD=automation -p 5984:5984 -d couchdb

curl localhost:5984


# PACKAGE_NAME="hcsshim"
# PACKAGE_VERSION=${1:-"0b7e02b"}
# PACKAGE_URL="https://github.com/microsoft/hcsshim"

# echo "installing dependencies from system repo..."
# dnf install wget git -y gcc gcc-c++ -q
# wget https://oplab9.parqtec.unicamp.br/pub/repository/rpm/open-power-unicamp.repo
# mv open-power-unicamp.repo /etc/yum.repos.d/
# echo "installing docker..."
# dnf -y install docker-ce -q
# systemctl start docker
# dnf install -qy golang git make gcc gcc-c++ cpio make
# HOME_DIR=$(pwd)
# cd "$HOME_DIR"
# git clone $PACKAGE_URL $PACKAGE_NAME
# cd $PACKAGE_NAME
# git checkout "$PACKAGE_VERSION"
# go build ./cmd/gcs
# docker pull busybox
# docker run --name base_image_container busybox
# docker export base_image_container | gzip >base.tar.gz
# BASE=./base.tar.gz
# mkdir bin
# cd vsockexec
# gcc -c vsockexec.c
# gcc -c vsock.c
# gcc vsockexec.c vsock.o -o vsockexec
# cp vsockexec ../bin/
# cd ../init
# gcc -c init.c
# gcc init.c ../vsockexec/vsock.o -o init
# cp init ../bin/
# cd ..
# make all
# make test