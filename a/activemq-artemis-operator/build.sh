#----------------------------------------------------------------------------
#
# Package         : artemiscloud/activemq-artemis-operator
# Version         : master
# Source repo     : https://github.com/artemiscloud/activemq-artemis-operator.git
# Tested on       : rhel_7.8
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
# docker must be installed and running.
#
# Go version 1.13.1 or later must be installed.
#
# oc client version 4.18 must be installed.
# Deployment tested on Openshift 4.3 setup
# python must be installed
# cekit and buildah must be installed

# ----------------------------------------------------------------------------
set -e
yum update -y
yum install git -y
export CWD=`pwd`

# build activemq-artemis-broker-image
git clone https://github.com/artemiscloud/activemq-artemis-broker-image.git
cd activemq-artemis-broker-image
git checkout v0.1.0

# Building Image
cekit build docker

cd $CWD
# Building Image
git clone https://github.com/artemiscloud/activemq-artemis-broker-kubernetes-image.git
cd activemq-artemis-broker-kubernetes-image
git checkout v0.1.0
mv -f ../image.yaml .
git add .
git commit -m "image.yaml modified"

# Building Image
cekit build docker

#Building Image ActiveMQ Operator
#----------------------------------
cd $CWD

git clone https://github.com/artemiscloud/activemq-artemis-operator.git
cd activemq-artemis-operator
docker build -f build/Dockerfile -t activemq-artemis-operator:latest .

#push images ocp registry
#-------------------------
#oc new-project activemq-artemis-operator|| true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=<project_name> || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

#docker tag activemq-artemis-operator:latest $HOST/activemq-artemis-operator/activemq-artemis-operator:latest
#docker tag quay.io/artemiscloud/activemq-artemis-broker:0.2.0 $HOST/activemq-artemis-operator/activemq-artemis-broker:0.2.0
#docker login -u kubeadmin -p $(oc whoami -t) $HOST
#docker push $HOST/activemq-artemis-operator/activemq-artemis-operator:latest
#docker push $HOST/activemq-artemis-operator/activemq-artemis-broker:0.2.0
