# ----------------------------------------------------------------------------
#
# Package         : che-incubator/kubernetes-image-puller
# Version         : master
# Source repo     : https://github.com/che-incubator/kubernetes-image-puller
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Vikas Kumar <kumar.vikas@in.ibm.com>
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

VERSION=master

set -e
yum update -y
yum install git -y

mkdir che-incubator && cd $_
git clone https://github.com/che-incubator/kubernetes-image-puller.git
cd kubernetes-image-puller
git checkout $VERSION

# Building Images
# build non-UBI image
docker build -t kubernetes-image-puller:latest -f docker/Dockerfile .

# build UBI image
docker build -t kubernetes-image-puller:latest-ubi8 -f docker/rhel.Dockerfile .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project local-images || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag kubernetes-image-puller:latest  $HOST/local-images/kubernetes-image-puller:latest
#docker tag kubernetes-image-puller:latest-ubi8  $HOST/local-images/kubernetes-image-puller:latest-ubi8

#docker login -u kubeadmin -p $(oc whoami -t) $HOST
#docker push $HOST/local-images/kubernetes-image-puller:latest
#docker push $HOST/local-images/kubernetes-image-puller:latest-ubi8
