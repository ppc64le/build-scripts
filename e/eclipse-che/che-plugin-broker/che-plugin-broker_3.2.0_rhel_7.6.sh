# ----------------------------------------------------------------------------
#
# Package         : eclipse/che-plugin-broker
# Version         : 7.13.1
# Source repo     : https://github.com/eclipse/che-plugin-broker
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Shivani Junawane <shivanij@us.ibm.com>
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
# docker and docker-docker must be installed and running.
#
# Go version 1.13.1 or later must be installed.
#
# oc client version 4.18 must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=v3.2.0

set -e
yum update -y
yum install git -y

export GOPATH=~/go
export GO111MODULE=auto

mkdir -p ${GOPATH}/src/github.com/eclipse && cd $_
git clone https://github.com/eclipse/che-plugin-broker.git
cd che-plugin-broker
git checkout $VERSION


# Building Image
# build Alpine image
docker build -t che-plugin-metadata-broker:$VERSION-alpine -f build/metadata/Dockerfile .
docker build -t che-plugin-artifacts-broker:$VERSION-alpine -f build/artifacts/Dockerfile .

# build UBI image
docker build -t che-plugin-metadata-broker:$VERSION-ubi -f build/metadata/rhel.Dockerfile .
docker build -t che-plugin-artifacts-broker:$VERSION-ubi -f build/artifacts/rhel.Dockerfile .

# Deploying on Openshift 4.3
#oc new-project local-images || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag che-plugin-metadata-broker:$VERSION-alpine $HOST/local-images/che-plugin-metadata-broker:$VERSION-alpine
#docker tag che-plugin-artifacts-broker:$VERSION-alpine $HOST/local-images/che-plugin-artifacts-broker:$VERSION-alpine
#docker tag che-plugin-metadata-broker:$VERSION-rhel $HOST/local-images/che-plugin-metadata-broker:$VERSION-rhel
#docker tag che-plugin-artifacts-broker:$VERSION-rhel $HOST/local-images/che-plugin-artifacts-broker:$VERSION-rhel

#docker login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
#docker push $HOST/local-images/che-plugin-metadata-broker:$VERSION-alpine
#docker push $HOST/local-images/che-plugin-artifacts-broker:$VERSION-alpine
#docker push $HOST/local-images/che-plugin-metadata-broker:$VERSION-rhel
#docker push $HOST/local-images/che-plugin-artifacts-broker:$VERSION-rhel


