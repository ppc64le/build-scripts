FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_NAME=stringi
ARG PACKAGE_VERSION=1.8.4

RUN yum install -y dnf && \
    dnf install -y gcc gcc-c++ gcc-gfortran git wget xz cmake make openssl-devel yum-utils sudo llvm && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/ && \
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official && \
    dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf install -y libtirpc.ppc64le && \
    dnf install -y R-core R-core-devel && \
    dnf builddep R -y && \
    git clone https://github.com/cran/stringi.git && \
    cd $PACKAGE_NAME && \
    git checkout $PACKAGE_VERSION && \
    cd .. && \
    R -e "install.packages('$PACKAGE_NAME', dependencies = TRUE, repos = 'http://cran.rstudio.com/')" && \
    R CMD build $PACKAGE_NAME --no-build-vignettes && \
    R CMD INSTALL $PACKAGE_NAME && \
    R CMD check $PACKAGE_NAME --no-build-vignettes --ignore-vignettes --no-manual

CMD ["/bin/bash"]
