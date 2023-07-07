FROM registry.access.redhat.com/ubi8:8.5

ARG PACKAGE_VERSION=v2.3.32

RUN yum -y update \
	&& yum -y install java-1.8.0-openjdk-devel wget git \
	&& wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.13-bin.tar.gz \
	&& tar xvfvz apache-ant-1.10.13-bin.tar.gz -C /opt \
	&& rm -rf apache-ant-1.10.13-bin.tar.gz \
	&& ln -s /opt/apache-ant-1.10.13 /opt/ant \
	&& sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment' \
	&& ln -s /opt/ant/bin/ant /usr/bin/ant \
	&& wget https://dlcdn.apache.org//ant/ivy/2.5.1/apache-ivy-2.5.1-bin.tar.gz \
	&& tar xvfvz apache-ivy-2.5.1-bin.tar.gz -C /opt/ant/lib \
	&& rm -rf apache-ivy-2.5.1-bin.tar.gz \
	&& wget https://dlcdn.apache.org//commons/lang/binaries/commons-lang3-3.12.0-bin.tar.gz \
	&& tar xvfvz commons-lang3-3.12.0-bin.tar.gz  -C /opt/ant/lib \
	&& rm -rf commons-lang3-3.12.0-bin.tar.gz \
	&& git clone https://github.com/apache/freemarker \
    && cd freemarker && git checkout $PACKAGE_VERSION \
    && ant download-ivy \
    && ant && ant test 

CMD ["/bin/bash"]