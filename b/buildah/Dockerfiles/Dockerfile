FROM registry.access.redhat.com/ubi8/ubi:8.5

MAINTAINER Pranav Pandit <pranav.pandit1@ibmc.om>

WORKDIR /home

#wget
RUN yum -y install wget && yum -y clean all  && rm -rf /var/cache

#JDK11
RUN dnf -y install java-11-openjdk-devel && \
java -version

#Maven
RUN dnf -y install maven && \
mvn -version

#buildah
RUN yum -y install buildah && \
buildah -v

#Helm
RUN wget  https://get.helm.sh/helm-v3.8.1-linux-ppc64le.tar.gz && \
tar -zxvf helm-v3.8.1-linux-ppc64le.tar.gz && \
mv linux-ppc64le/helm /usr/local/bin/helm && \
rm -rf helm-v3.8.1-linux-ppc64le.tar.gz && \
helm version

#OC Client
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.4/linux-ppc64le/oc.tar.gz && \
tar -zxvf oc.tar.gz && \
rm -rf oc.tar.gz && \
mv oc /usr/local/bin/ && \
mv kubectl /usr/local/bin/ && \
oc version

#Cleaning unwanted files & packaegs
RUN rm -rf *
RUN yum -y remove wget
