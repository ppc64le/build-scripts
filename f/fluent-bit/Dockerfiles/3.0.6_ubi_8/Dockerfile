FROM registry.access.redhat.com/ubi8/ubi:8.7 as build

ENV FLUENTBIT_VERSION=v3.0.6
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/f/fluent-bit/fluent-bit_${FLUENTBIT_VERSION}.patch

#Install required repos
RUN dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
    https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

RUN yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y

RUN cd /tmp \
    && git clone https://github.com/fluent/fluent-bit.git \
    && cd fluent-bit \
    && git checkout $FLUENTBIT_VERSION \
    && wget ${PATCH_FILE} \
    && git apply fluent-bit_${FLUENTBIT_VERSION}.patch \
    && cd build \
    && cmake -DFLB_RELEASE=On .. \
    && make -j $(nproc) \
    && mv bin/fluent-bit /bin/fluent-bit


FROM registry.access.redhat.com/ubi8/ubi:8.7

LABEL "name"="Fluent Bit"
LABEL "vendor"="IBM"
LABEL "version"="3.0.6"
LABEL "release"="3.0.6"
LABEL "summary"="Fluent Bit 3.0.6"
LABEL "description"="Fluent Bit 3.0.6"

RUN groupadd -r fluent --gid=1000; \
    useradd -r -g fluent --uid=1000 fluent;

COPY --from=build /bin/fluent-bit /bin/fluent-bit

RUN yum install wget -y \
    && mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log \
    && mv /bin/fluent-bit /fluent-bit/bin/ \
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

#Expose port
EXPOSE 2020

USER fluent

#Entry point
ENTRYPOINT ["/fluent-bit/bin/fluent-bit"]
CMD ["-c", "/fluent-bit/etc/fluent-bit.conf"]

