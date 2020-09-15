# ----------------------------------------------------------------------------
#
# Package	: Wildfly-Operator
# Version	: master
# Source repo	: https://github.com/wildfly/wildfly-operator
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Baheti <aramswar@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------#
# Prerequisites: 
#
# docker & podman must be installed and running
#
# ----------------------------------------------------------------------------

set -e
VERSION=master

# Build PhantomJS binary file from source code on Power
yum -y update
yum -y install make git 

git clone -b $VERSION https://github.com/wildfly/wildfly-operator.git
cd wildfly-operator && make image

# Deploying on Openshift 4.3
oc new-project local-images || true
oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
docker tag quay.io/wildfly/wildfly-operator  $HOST/local-images/wildfly-operator
podman pull docker-daemon:$HOST/local-images/wildfly-operator:latest

podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
podman push $HOST/local-images/wildfly-operator:latest --tls-verify=false
