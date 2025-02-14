FROM registry.access.redhat.com/ubi9

MAINTAINER Vinod K <Vinod.K1@ibm.com>

ARG PACKAGE_VERSION=v2.2.8

RUN yum install -y yum-utils git gcc-c++ gcc diffutils patch libtool automake autoconf make cmake  openssl-devel openssl \
    && git clone https://github.com/acassen/keepalived  \
    && cd keepalived  \
    && git checkout $PACKAGE_VERSION  \
    && ./autogen.sh \
    && ./configure \
        --disable-dynamic-linking \
        --prefix=/usr \
        --exec-prefix=/usr \
        --bindir=/usr/bin \
        --sbindir=/usr/sbin \
        --sysconfdir=/etc \
        --datadir=/usr/share \
        --localstatedir=/var \
        --mandir=/usr/share/man \
        --enable-bfd \
        --enable-json \
    && make && make install \
    && strip /usr/sbin/keepalived

ADD keepalived.conf /etc/keepalived/keepalived.conf

# set keepalived as image entrypoint with --dont-fork and --log-console (to make it docker friendly)
# define /etc/keepalived/keepalived.conf as the configuration file to use
ENTRYPOINT ["/usr/sbin/keepalived","--dont-fork","--log-console", "-f","/etc/keepalived/keepalived.conf"]
