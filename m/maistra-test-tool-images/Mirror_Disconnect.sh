#!/bin/bash

BREW_PASSWORD=""
QUAY_USERNAME=""
QUAY_PASSWORD=""
REDHAT_USERNAME=""
REDHAT_PASSWORD=""
OC_USERNAME="kubeadmin"
OC_PASSWORD=""
BUILD_VERSION=maistra-2.0-p
BOOKINFO_NAMESPACE=bookinfo

export REG_CRED="${XDG_RUNTIME_DIR}/containers/auth.json"

#login to brew registry
podman login --username "|shared-qe-temp.src5.75b4d5" --password $BREW_PASSWORD
if [ $? != 0 ]; then
        echo "Invalid brew credentials"
        exit 0
fi

#login to quay registry
echo "login to quay registry"
podman login quay.io --username $QUAY_USERNAME --password $QUAY_PASSWORD
if [ $? != 0 ]; then
        echo "Invalid quay credentials"
        exit 0
fi

#login to redhat registry
echo "login to redhat registry"
podman login registry.redhat.io --username $REDHAT_USERNAME --password $REDHAT_PASSWORD

if [[ (-z "$OC_USERNAME") || (-z "$OC_PASSWORD") ]]; then
    read -p "Enter oc cluster username" OC_USERNAME
    read -p "Enter oc cluster password" OC_PASSWORD
fi
#login to oc cluster
oc login -u $OC_USERNAME -p $OC_PASSWORD --insecure-skip-tls-verify
if [ $? != 0 ]; then
        echo "Invalid credentials"
        exit 0
fi

cluster_url=$(oc cluster-info | cut -d$'\n' -f 1| cut -d ' ' -f 6)
echo "cluster_url $cluster_url"
OLDIFS=$IFS
IFS=.
read -a strarr <<< "$cluster_url"
IFS=$OLDIFS
strarr[0]="registry"
strarr[-1]="io:5000"

local_registry=${strarr[0]}
for val in "${strarr[@]:1}";
do
        local_registry=$local_registry.${val}
done
echo "local_registry $local_registry"


#login to local registry
podman login "$local_registry"

cat ${REG_CRED}

#mirroring images
oc image mirror quay.io/maistra/examples-bookinfo-details-v1:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-details-v1:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-details-v1:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-productpage-v1:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-productpage-v1:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-productpage-v1:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-ratings-v1:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-ratings-v1:2.0.0-ibm-p -a ${REG_CRED}
oc image info  $local_registry/maistra/examples-bookinfo-ratings-v1:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-reviews-v1:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-reviews-v1:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-reviews-v1:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-reviews-v2:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-reviews-v2:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-reviews-v2:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-reviews-v3:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-reviews-v3:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-reviews-v3:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-mongodb:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-mongodb:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-mongodb:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-ratings-v2:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-ratings-v2:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-ratings-v2:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/examples-bookinfo-mysqldb:2.0.0-ibm-p $local_registry/maistra/examples-bookinfo-mysqldb:2.0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/examples-bookinfo-mysqldb:2.0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/governmentpaas-curl-ssl:0.0-ibm-p $local_registry/maistra/governmentpaas-curl-ssl:0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/governmentpaas-curl-ssl:0.0-ibm-p -a ${REG_CRED}

oc image mirror quay.io/maistra/tcp-echo-server:0.0-ibm-p $local_registry/maistra/tcp-echo-server:0.0-ibm-p -a ${REG_CRED}
oc image info $local_registry/maistra/tcp-echo-server:0.0-ibm-p -a ${REG_CRED}

if [ -d "$HOME/maistra-test-tool" ]; then
        rm -rf "maistra-test-tool"
fi

# Install Go
wget https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
rm -rf go1.13.5.linux-ppc64le.tar.gz
go get github.com/bazelbuild/bazelisk
export PATH=$PATH:$(go env GOPATH)/bin
echo "$PATH"

cd $HOME
git clone https://github.com/maistra/maistra-test-tool/
cd maistra-test-tool
git checkout $BUILD_VERSION

#maistra prerequisite
chmod +x scripts/setup_ocp_scc_anyuid.sh;
scripts/setup_ocp_scc_anyuid.sh

cd $HOME/maistra-test-tool/tests

#Replace image registry name with local registry
sed  -i -e "s|quay.io|$local_registry|g" samples/bookinfo/platform/kube/bookinfo-db.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/bookinfo/platform/kube/bookinfo-mysql.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/bookinfo/platform/kube/bookinfo.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/sleep/sleep.yaml
sed  -i -e "s|quay.io|$local_registry|g" samples/tcp-echo/tcp-echo-services.yaml

#To create book info :
oc new-project ${BOOKINFO_NAMESPACE} || true
oc project ${BOOKINFO_NAMESPACE}

oc create -f samples/bookinfo/platform/kube/bookinfo.yaml
oc create -f samples/bookinfo/networking/bookinfo-gateway.yaml
oc create -f samples/bookinfo/networking/destination-rule-all.yaml
oc create -f samples/bookinfo/platform/kube/bookinfo-db.yaml
oc create -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
oc apply -f samples/bookinfo/platform/kube/bookinfo-db.yaml
oc apply -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
oc apply -f samples/bookinfo/platform/kube/bookinfo-mysql.yaml
oc apply -f samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml
oc get all

#Run maistra test 01
go test -run 01 -timeout 1h -v

