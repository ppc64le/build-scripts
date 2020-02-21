# ----------------------------------------------------------------------------
#
# Package	: nfs-client-provisioner
# Version	: 2.0.1
# Source repo	: https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client
# Tested on	: ubi8
# Script License: Apache License, Version 2 or later
# Maintainer	: Pratham Murkute <prathamm@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#			  This script assumes that dependent packages like golang version 
#			  go1.12.1 linux/ppc64le, git, wget, kubectl are already installed 
#			  on the system.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# install dependent packages
yum -y update
#yum install -y git libtool libtool-bin make build-essential

# create necessary directories 
cd /root/
mkdir -p /go/
mkdir -p /go/src/
mkdir -p /go/bin/
cd ./go/src/

# set golang environment variables 
export GOPATH=/root/go/

# clone and compile the code
git clone https://github.com/kubernetes-incubator/external-storage.git
cd external-storage/nfs-client/
make build_ppc64le image_ppc64le
echo "Build completed..."

# start deployment of the provisioner
# refer https://github.com/kubernetes-incubator/external-storage/blob/master/nfs-client/README.md for details
echo "Starting deployment..."

# set the subject of the RBAC objects to the current namespace where the provisioner is being deployed
NS=$(kubectl config get-contexts|grep -e "^\*" |awk '{print $5}')
NAMESPACE=${NS:-default}
sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml ./deploy/deployment-ppc64le.yaml
kubectl create -f deploy/rbac.yaml

# update NFS_SERVER and NFS_PATH in deployment-ppc64le.yaml
NFS_SERVER=127.0.0.1	#note: change as per local setup
NFS_PATH=/nfs			#note: change as per local setup
sed -i'' "37 s/value:.*/value: $NFS_SERVER/" ./deploy/deployment-ppc64le.yaml	#note: line 37 may change
sed -i'' "s/server:.*/server: $NFS_SERVER/g" ./deploy/deployment-ppc64le.yaml
sed -i'' "40 s#value:.*#value: $NFS_PATH#" ./deploy/deployment-ppc64le.yaml		#note: line 40 may change
sed -i'' "s#path:.*#path: $NFS_PATH#g" ./deploy/deployment-ppc64le.yaml

# create POD and storage-class for provisioner
kubectl create -f deploy/deployment-ppc64le.yaml
kubectl create -f deploy/class.yaml

# test the deployed provisioner
kubectl create -f deploy/test-claim.yaml -f deploy/test-pod-ppc64le.yaml

# display deployment details 
echo "Displaying stats..."
echo "deployments:"
kubectl get deployments
echo "storageclass:"
kubectl get storageclass
echo "pods:"
kubectl get pods
echo "pvc:"
kubectl get pvc
echo ""
