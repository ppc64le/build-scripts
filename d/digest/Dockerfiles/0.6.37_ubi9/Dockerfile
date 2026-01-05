FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_NAME=digest
ARG PACKAGE_VERSION=0.6.37

RUN dnf install -y gcc gcc-c++ gcc-gfortran git wget xz cmake make yum-utils wget sudo llvm  && \
	dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
	dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
	dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/ && \
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official &&\
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official 

RUN dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf install -y libtirpc.ppc64le && \
    dnf install -y R-core R-core-devel && \
    dnf builddep R -y

RUN dnf install -y geos-devel gdal-devel udunits2-devel unixODBC-devel libpq-devel proj-devel sqlite-devel gsl-devel libgit2-devel libcurl-devel libarchive-devel openssl-devel
 
RUN git clone https://github.com/cran/digest.git && \
    cd digest && \
    git checkout $PACKAGE_VERSION && \
    cd ..

RUN R -e "install.packages('$PACKAGE_NAME', dependencies = TRUE, repos = 'http://cran.rstudio.com/')" && \
    R CMD build $PACKAGE_NAME --no-build-vignettes && \
    R CMD INSTALL $PACKAGE_NAME && \
    R CMD check $PACKAGE_NAME --no-build-vignettes --ignore-vignettes --no-manual

CMD ["/bin/bash"]
