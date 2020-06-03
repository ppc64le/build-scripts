# ----------------------------------------------------------------------------
#
# Package         : theia-python-docker
# Version         : master
# Source repo     : https://github.com/theia-ide/theia-apps/tree/master/theia-python-docker
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Sailaja Chavali <sachav83@in.ibm.com>
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
# podman and podman-docker must be installed and running.
#
# oc client version 4.3.21 must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=master

set -e
yum update -y
yum install git -y

mkdir theia-ide && cd $_
git clone https://github.com/theia-ide/theia-apps.git
cd theia-apps/theia-python-docker
git checkout $VERSION

# Building Image
# build Python image with latest Version
podman build -t theia-python:latest .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project python-docker || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=python-docker || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST
#podman tag theia-python:latest $HOST/python-docker/theia-python:latest
#podman push $HOST/python-docker/theia-python:latest --tls-verify=false
