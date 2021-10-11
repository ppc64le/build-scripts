#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : Strimzi
# Version       : master
# Source repo   : https://github.com/strimzi/strimzi-kafka-operator.git
# Tested on     : Ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Vijay Kumar H P <vijaykh1@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------- 
# ----------------------------------------------------------------------------
# Prerequisites:
#
# Docker must be installed and running
# Running k8s cluster
# Helm must be installed and running
# ----------------------------------------------------------------------------

## Install command line utilities to build this project
set -e
apt install -y maven
apt install -y asciidoctor
apt install -y ruby
apt install -y make
apt install -y openjdk-11-jre-headless
apt install -y openjdk-11-jdk-headless
wget https://github.com/mikefarah/yq/releases/download/v4.4.1/yq_linux_ppc64le.tar.gz -O - | tar xz && mv yq_linux_ppc64le /usr/bin/yq

# Building container images with Docker buildx

wget https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-ppc64le
mkdir -p ~/.docker/cli-plugins
mv buildx-v0.5.1.linux-ppc64le ~/.docker/cli-plugins/docker-buildx
chmod a+x ~/.docker/cli-plugins/docker-buildx
export DOCKER_BUILDX=buildx
export DOCKER_BUILD_ARGS="--platform linux/ppc64le --load"
docker buildx ls

HOST=<Docker-repo>
docker login -u <username> -p <pwd> $HOST
export DOCKER_ORG=<username>
export DOCKER_REGISTRY=$HOST



## Clone , modify Dockerfiles and Build Strimzi operator package
git clone https://github.com/strimzi/strimzi-kafka-operator.git
cp base/Dockerfile strimzi-kafka-operator/docker-images/base/
cp kafka/Dockerfile strimzi-kafka-operator/docker-images/kafka/
cd strimzi-kafka-operator
make all