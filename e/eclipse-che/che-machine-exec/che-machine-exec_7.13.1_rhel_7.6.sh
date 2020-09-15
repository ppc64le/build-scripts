#----------------------------------------------------------------------------
#
# Package         : eclipse/che-machine-exec
# Version         : 7.13.1
# Source repo     : https://github.com/eclipse/che-machine-exec
# Tested on       : rhel_7.6
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
# docker version supporting multistage builds must be installed and running.
#
# The internal resgistry should be set as insecure registry in docker daemon settings.
#
# oc client version 4.18 or above must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=7.13.1

set -e
yum update -y
yum install git -y

mkdir eclipse && cd $_
git clone https://github.com/eclipse/che-machine-exec.git
cd che-machine-exec
git checkout $VERSION

# Building Image
# build Apline image
docker build --no-cache -f build/dockerfiles/Dockerfile -t eclipse/che-machine-exec:${VERSION} .

# build UBI image
docker build --no-cache -f build/dockerfiles/rhel.Dockerfile -t eclipse/che-machine-exec:${VERSION}-ubi8 .

# Deploying on Openshift 4.3
#oc new-project che-machine-exec || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=che-machine-exec || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag eclipse/che-machine-exec:${VERSION} $HOST/che-machine-exec/che-machine-exec:${VERSION}
#docker tag eclipse/che-machine-exec:${VERSION}-ubi8 $HOST/che-machine-exec/che-machine-exec:${VERSION}-ubi8

#docker login -u kubeadmin -p $(oc whoami -t) $HOST
#docker push $HOST/che-machine-exec/che-machine-exec:${VERSION}
#docker push $HOST/che-machine-exec/che-machine-exec:${VERSION}-ubi8
