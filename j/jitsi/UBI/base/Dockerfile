FROM registry.access.redhat.com/ubi8-minimal

ARG JITSI_RELEASE=stable

ARG ARCH=ppc64le

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs /

#COPY frep-1.3.11-linux-ppc64le /usr/bin/frep

RUN     set -e; \
        microdnf update && microdnf install -y yum && \
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
        yum update -y && \
        yum install -y ca-certificates gnupg wget git gcc-c++ tar gzip && \
#        ln -s /usr/bin/sh /bin/sh && \
        wget -qO - https://golang.org/dl/go1.15.2.linux-${ARCH}.tar.gz  | tar xfz - -C /usr && \
        export PATH=/usr/go/bin/:$PATH && \
        wget -q https://github.com/subchen/frep/releases/download/v1.3.12/frep-1.3.12-linux-ppc64le && mv frep-1.3.12-linux-ppc64le /usr/bin/frep && \
        chmod +x /usr/bin/frep && \
        cp /bin/sh /root/ && \
        wget -qO - https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.0/s6-overlay-${ARCH}.tar.gz | tar xfz - -C / && \
        cp /root/sh /bin/
       
RUN     set -e;\
#        ln -s /usr/bin/sh /bin/sh && \
	yum update && \
	yum install -y jq procps curl vim iputils net-tools

ENV PATH=/bin:$PATH

ENTRYPOINT [ "/init" ]
