# ----------------------------------------------------------------------------
#
# Package        : maistra
# Version        : 2.0
# Source repo    : https://github.com/maistra/istio.git
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Rashmi Sakhalkar <srashmi@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WORKDIR=`pwd`
REPO_VERSION=maistra-2.0
VERSION='1.15.0-ibm-p'
PREFIX=maistra

git clone https://github.com/maistra/istio
cd istio
git checkout $REPO_VERSION

#Build details 
cd samples/bookinfo/src/details/
podman build -t "${PREFIX}/examples-bookinfo-details-v1:${VERSION}" .

#Build product 
cd ../productpage
sed -i '/^FROM python.*$/aRUN if [ "`uname -m`" = "ppc64le" ]; then apt-get update && apt-get install -y build-essential; fi' Dockerfile
podman build -t "${PREFIX}/examples-bookinfo-productpage-v1:${VERSION}" .

#Build ratings
cd ../ratings
sed -i '/^FROM node.*$/aRUN if [ "`uname -m`" = "ppc64le" ]; then apt-get update && apt-get upgrade -y && apt-get install -y libatomic1; fi' Dockerfile
podman build -t "${PREFIX}/examples-bookinfo-ratings-v1:${VERSION}" .

#Build reviews v1 & v2 image
cd ../reviews
podman build --pull -t "${PREFIX}/examples-bookinfo-reviews-v1:${VERSION}" -t "${PREFIX}/examples-bookinfo-reviews-v1:latest" --build-arg service_version=v1 .
podman build --pull -t "${PREFIX}/examples-bookinfo-reviews-v2:${VERSION}" -t "${PREFIX}/examples-bookinfo-reviews-v2:latest" --build-arg service_version=v2 --build-arg enable_ratings=true .


##Build mongo
cd ../mongodb
sed -i 's+FROM mongo:4.0.12-xenial+FROM ppc64le/mongodb:2.6.10+g' Dockerfile
podman build -t "${PREFIX}/examples-bookinfo-mongodb:${VERSION}" .

##Build mysql
cd ../mysql
sed -i 's+FROM mysql:8.0.17+FROM ppc64le/mariadb:10.5+g' Dockerfile
podman build -t "${PREFIX}/examples-bookinfo-mysqldb:${VERSION}" .