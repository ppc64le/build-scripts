FROM registry.access.redhat.com/ubi8/ubi:8.4

ARG PACKAGE_VERSION=${1:-6.2.3rc1}


RUN curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
        dnf install -y epel-release-latest-8.noarch.rpm && \
        rm -f epel-release-latest-8.noarch.rpm

RUN yum install -y wget yum-utils && \
        yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ && \
        yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/ && \
        yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/ && \
        yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/virt/ppc64le/ovirt-44/ && \
        wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
        mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official && \
        wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && \
        mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

RUN yum install -y initscripts httpd tar wget curl vim gcc make net-snmp php-mysqlnd  git httpd php libcurl-devel libxml2-devel php-xml php-gd php-bcmath php-mbstring php-ldap php-json libevent-devel pcre-devel cmake policycoreutils-python-utils automake pkgconfig gcc-c++ autoconf automake libtool procps yum-utils libcmocka-devel libyaml-devel perl-YAML-LibYAML libpath_utils-devel perl-IPC-Run3 perl-Path-Tiny mariadb-devel libxml2-devel net-snmp-devel OpenIPMI-devel libevent-devel libcurl-devel pcre-devel

RUN git clone https://github.com/zabbix/zabbix && \
    cd zabbix && \
    git checkout $PACKAGE_VERSION && \
    ./bootstrap.sh tests && \
    ./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --with-openipmi && \
    make && \
    make install && \
    make tests

CMD [ "/bin/bash" ]

