#Dockerfile for building Nova on Ubuntu 14.04
FROM ppc64le/ubuntu:14.04

#Owner of docker file
MAINTAINER kiritim@us.ibm.com

RUN apt-get update -y && apt-get install software-properties-common -y && \
        add-apt-repository cloud-archive:mitaka -y
RUN apt-get update -y && \
        apt-get install -y python-openstackclient \
                nova-api \
                nova-conductor \
                nova-consoleauth \
                nova-novncproxy \
                nova-scheduler \
                python-mysqldb \
                mysql-client \
                neutron-plugin-ml2 \
                python-memcache && \
    rm -f /var/lib/nova/nova.sqlite

EXPOSE 8774
ADD nova.conf /etc/nova/
ADD nova_setup.sh /
RUN chmod 755 nova_setup.sh
CMD ./nova_setup.sh
