FROM registry.access.redhat.com/ubi8/ubi:8.6

ENV FLUENTBIT_VERSION=v2.0.11
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/f/fluent-bit/fluent-bit-${FLUENTBIT_VERSION}.patch

#Install required repos
RUN dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
    https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

#Install dependencies
RUN yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel \
    cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y

#Clone and apply patch
RUN cd /tmp \
    && git clone https://github.com/fluent/fluent-bit.git \
    && cd fluent-bit \
    && git checkout $FLUENTBIT_VERSION \
    && wget ${PATCH_FILE} \
    && git apply fluent-bit-${FLUENTBIT_VERSION}.patch

#Build
WORKDIR /tmp/fluent-bit/build/
RUN cmake -DFLB_RELEASE=On .. \
    && make -j $(nproc)

#Copy binary and configs
RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log \
    && install bin/fluent-bit /fluent-bit/bin/ \
    && cd /fluent-bit/etc/ \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/fluent-bit.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_ambassador.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_cinder.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_extra.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_java.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_mult.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/parsers_openstack.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.8.11/conf/plugins.conf

#Cleanup
RUN rm -rf /tmp/fluent-bit \
    && yum remove gcc gcc-c++ wget cmake3 python3 git diffutils autoconf postgresql-devel -y

#Expose port
EXPOSE 2020

#Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]

