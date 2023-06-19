FROM registry.access.redhat.com/ubi8/ubi:8.7

LABEL "name"="Fluent Bit"
LABEL "vendor"="IBM"
LABEL "version"="1.6.10"
LABEL "release"="1.6.10"
LABEL "summary"="Fluent Bit 1.6.10"
LABEL "description"="Fluent Bit 1.6.10"

ENV FLUENTBIT_VERSION=v1.6.10
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/f/fluent-bit/fluent-bit_${FLUENTBIT_VERSION}.patch

RUN groupadd -r fluent --gid=1000; \
    useradd -r -g fluent --uid=1000 fluent;

RUN dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
    https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

RUN yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y \
    && mkdir /licenses \
    && cd /licenses \
    && wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/f/fluent-bit/LICENSE \
    && cd /tmp \
    && git clone https://github.com/fluent/fluent-bit.git \
    && cd fluent-bit \
    && git checkout $FLUENTBIT_VERSION \
    && wget ${PATCH_FILE} \
    && git apply fluent-bit_${FLUENTBIT_VERSION}.patch \
    && cd lib \
    && git clone https://github.com/moonjit/moonjit.git \
    && mv moonjit luajit2 \
    && cd luajit2 \
    && git checkout 2.2.0 \
    && sed -i '24i #if LJ_ARCH_PPC_ELFV2' src/lj_ccallback.c \
    && sed -i '25i #include "lualib.h"' src/lj_ccallback.c \
    && sed -i '26i #endif' src/lj_ccallback.c \
    && echo "exit 0;" >> configure \
    && chmod +x configure \
    && cd ../../build \
    && cmake .. -DFLB_TESTS_RUNTIME=On -DFLB_TESTS_INTERNAL=On  \
    && make -j $(nproc) \
    && mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log \
    && install bin/fluent-bit /fluent-bit/bin/ \
    && cd /fluent-bit/etc/ \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/fluent-bit.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_ambassador.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_cinder.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_extra.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_java.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_mult.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/parsers_openstack.conf \
    && wget https://raw.githubusercontent.com/fluent/fluent-bit-docker-image/1.6.10/conf/plugins.conf \
    && rm -rf /tmp/fluent-bit \
    && yum remove gcc gcc-c++ wget cmake3 python3 git diffutils autoconf postgresql-devel libyaml-devel cyrus-sasl-devel systemd-devel valgrind-devel glibc-devel openssl-devel nmap-cat nmap nc flex bison -y

#Expose port
EXPOSE 2020

USER fluent

#Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]

