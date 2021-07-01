# ----------------------------------------------------------------------------
#
# Package          : fate-operator
# Version          : latest
# Source repo      : https://github.com/kubeflow/fate-operator
# Tested on        : CentOS Linux release 8.3.2011
# Passing Arguments: Configure with command no argument required
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rajesh kumar <rajesh.kumar13@ibm.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#pre-requisite instalation :

#Go lang instalation
		wget https://golang.org/dl/go1.15.8.linux-ppc64le.tar.gz
		sudo tar -xvf go1.15.8.linux-ppc64le.tar.gz
		sudo mv go /usr/local
		sudo tar -xvf go1.15.8.linux-ppc64le.tar.gz
		sudo mv go $HOME/
#	Setting classpath for go
		export GOROOT=/usr/local/go
		export GOPATH=$HOME/go
		export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
#	Adding to environment variable 
		source ~/.profile
	
	
#Minikube installation

		wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-ppc64le 
		sudo cp minikube-linux-ppc64le /usr/local/bin/minikube
		sudo chmod 755 /usr/local/bin/minikube
		cd /usr/local/bin/minikube
		./minikube start
		
		
#kustomize installation
		
		https://github.com/ezeeyahoo/kustomize/releases/tag/kustomize%2Fv3.5.4
		
		mkdir -p ${HOME}/bin
		mv kustomize ${HOME}/bin/kustomize
		chmod u+x ${HOME}/bin/kustomize

#	Adding to environemnt variable
		export PATH=$PATH:${HOME}/bin

		kubectl config view
		kubectl version --client
#conntrack installation
		
		sudo yum install conntrack
		
		git clone https://github.com/kubeflow/fate-operator.git
		
		cd fate-operator
		
		sed -i 's/amd64/ppc64le/g' Dockerfile
		
		go test ./... -coverprofile cover.out

		go build -o bin/fate-operator main.go

		go run ./main.go
		
#building docker image

docker build -t federatedai/fate-controller:latest .
