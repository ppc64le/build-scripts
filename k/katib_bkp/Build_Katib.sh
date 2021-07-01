#Katib_build.sh
# ----------------------------------------------------------------------------
#
# Package          : katib
# Version          : latest
# Source repo      : https://github.com/kubeflow/katib
# Tested on        : Fedora Linux release 5.7.16-200.fc32.ppc64le
# Passing Arguments: Configure with command no argument required
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ujjwal Sharma <ujjwal.cpp@gmail.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#

#!/bin/bash

export REPO=https://github.com/kubeflow/katib

#Go lang instalation and environment setting
sudo apt-get update
sudo apt-get install wget git -y
wget https://golang.org/dl/go1.15.8.linux-ppc64le.tar.gz
sudo tar -xvf go1.15.8.linux-ppc64le.tar.gz
sudo mv go /usr/local
sudo tar -xvf go1.15.8.linux-ppc64le.tar.gz
sudo mv go $HOME/
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
source ~/.profile

npm install --global prettier@2.2.0

#minikube Deploy

wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-ppc64le
sudo cp minikube-linux-ppc64le /usr/local/bin/minikube
sudo chmod 755 /usr/local/bin/minikube
cd /usr/local/bin/minikube
./minikube start

# minikube deploy end


#kubebuilder deploy 
wget https://github.com/kubernetes-sigs/kubebuilder/releases/download/v1.0.7/kubebuilder_1.0.7_linux_amd64.tar.gz
sudo tar -xvf kubebuilder_1.0.7_linux_amd64.tar.gz
sudo mv kubebuilder_1.0.7_linux_amd64 /usr/local/kubebuilder
# END

#kustomize installation

https://github.com/ezeeyahoo/kustomize/releases/tag/kustomize%2Fv3.5.4
mkdir -p ${HOME}/bin
mv kustomize ${HOME}/bin/kustomize
chmod u+x ${HOME}/bin/kustomize

#kustomize
export PATH=$PATH:${HOME}/bin
kubectl config view
kubectl version --client

git clone ${REPO}
cd katib
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi
make prettier-check
make check
make test
