vault-k8s 1.2.1 - Steps to build binary and the docker image
-------------------------------------------------------------
1. Start the docker container
   docker run -t -d --privileged --name vault-k8s -v /var/run/docker.sock:/var/run/docker.sock registry.access.redhat.com/ubi8/ubi:8.7 /usr/sbin/init
2. Connect to the docker container
   docker exec -it vault-k8s bash
3. Download and run the script
   yum install wget -y
   wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/v/vault-k8s/vault-k8s-1.2.1-ubi-8.7.sh
   chmod +x vault-k8s-1.2.1-ubi-8.7.sh
   source ./vault-k8s-1.2.1-ubi-8.7.sh
   echo $VAULTK8S_BIN
   echo $IMAGE_TAG
4. List docker image on the host
   docker images | grep vault-k8s
