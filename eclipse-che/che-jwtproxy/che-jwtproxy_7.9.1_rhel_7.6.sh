# ----------------------------------------------------------------------------
#
# Package         : che-jwtproxy
# Version         : master
# Source repo     : https://github.com/eclipse/che-jwtproxy
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Bivas Das <bivasda1@ibm.com>
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
# docker version supporting multistage builds must be installed and running.
#
# The internal resgistry should be set as insecure registry in docker daemon settings.
#
# oc client version 4.18 or above must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=7.9.1

set -e
yum update -y
yum install git -y

#export GOPATH=~/go
#export GO111MODULE=auto

mkdir eclipse && cd $_
git clone https://github.com/eclipse/che-jwtproxy.git
cd che-jwtproxy
git checkout $VERSION

# Building Image
# build Alpine image
docker build -t che-jwtproxy:latest -f Dockerfile .

# build UBI image
docker build -t  che-jwtproxy-ubi:latest -f rhel.Dockerfile .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project jwtproxy || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=jwtproxy || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag che-jwtproxy:latest $HOST/jwtproxy/che-jwtproxy
#docker tag che-jwtproxy-ubi:latest $HOST/jwtproxy/che-jwtproxy-ubi
#docker login -u kubeadmin -p $(oc whoami -t) $HOST
#docker push $HOST/jwtproxy/che-jwtproxy:latest
#docker push $HOST/jwtproxy/che-jwtproxy-ubi:latest
