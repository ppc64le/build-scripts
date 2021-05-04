# ----------------------------------------------------------------------------
#
# Package         : eclipse-che
# Version         : 7.26.2
# Tested on       : rhel_7.8
# Script License  : Apache License, Version 2.0
# Maintainer      : Bivas Das <bivasda1@ibm.com>
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
# yarn version v1.22.5 must be installed.
# Go version 1.13.1 or later must be installed.
#
# oc client version 4.18 must be installed.
# Deployment tested on Openshift 4.5 setup
# ----------------------------------------------------------------------------
#yum update -y
#yum install git -y
#yum install wget -y
#yum install gcc-c++ -y
#yum install -y net-snmp-libs.ppc64le net-snmp-agent-libs.ppc64le make

export CWD=`pwd`

VERSION=7.26.2

#install OpenJDK11U
cd /opt/
wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2020-10-14-16-30/OpenJDK11U-jre_ppc64le_linux_openj9_2020-10-14-16-30.tar.gz
mkdir -p /opt/java/openjdk
cd /opt/java/openjdk/
tar -xf /opt/OpenJDK11U-jre_ppc64le_linux_openj9_2020-10-14-16-30.tar.gz   --strip-components=1
export PATH=/opt/java/openjdk/bin:$PATH

#install maven
cd /opt/
wget https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar -xvzf apache-maven-3.6.2-bin.tar.gz
export PATH=/opt/apache-maven-3.6.2/bin/:$PATH

# install chectl
cd /opt/
wget https://github.com/che-incubator/chectl/releases/download/20201021153243/chectl-linux-ppc64le.tar.gz
tar -xvzf chectl-linux-ppc64le.tar.gz
export PATH=/opt/chectl/bin/:$PATH

cd $CWD

#build che-oprator
git clone https://github.com/eclipse/che-operator.git
cd che-operator
git checkout $VERSION
docker build -t che-operator:latest -f Dockerfile .

cd $CWD

# build che-plugin-registry
git clone https://github.com/eclipse/che-plugin-registry.git
git checkout $VERSION
cd che-plugin-registry
./build.sh -t 7.26.2 --rhel

cd $CWD

#build che-devfile-registry

git clone https://github.com/eclipse/che-devfile-registry.git
cd che-devfile-registry
git checkout $VERSION
./build.sh -t 7.26.2 --rhel

cd $CWD

#build keyclaok-server

git clone -b 6.0.1 https://github.com/keycloak/keycloak-containers.git
mv -f Dockerfile keycloak-containers/server/Dockerfile
cd keycloak-containers/server
docker build -t jboss/keycloak:6.0.1 -f Dockerfile .

cd $CWD

#build che-server

git clone https://github.com/eclipse/che.git
cd che
git checkout $VERSION
mvn -f assembly/assembly-main clean install
cd dockerfiles/che
./build.sh -t che-server:next

cd $CWD

#build che-keycloak
cd che/dockerfiles/keycloak
./build.sh -t next

#push images ocp registry

#oc new-project che || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=<project_name> || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag che-operator:latest $HOST/che/che-operator:latest
#docker tag che-plugin-registry:7.26.2 $HOST/che/che-plugin-registry:latest
#docker tag che-devfile-registry:7.26.2 $HOST/che/che-devfile-registry:latest
#docker tag che-keycloak:next $HOST/che/che-keycloak:latest
#docker tag che-server:next $HOST/che/che-server:next

#docker login -u kubeadmin -p $(oc whoami -t) $HOST
#docker push $HOST/che/che-operator:latest
#docker push $HOST/che/che-plugin-registry:latest
#docker push $HOST/che/che-devfile-registry:latest
#docker push $HOST/che/che-keycloak:latest
#docker push $HOST/che/che-server:next
