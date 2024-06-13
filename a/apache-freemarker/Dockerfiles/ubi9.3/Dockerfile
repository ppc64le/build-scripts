FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=v2.3.32

RUN yum -y update && yum install -y java-1.8.0-openjdk-devel wget git  && \
    wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.13-bin.tar.gz && \
    tar xvfvz apache-ant-1.10.13-bin.tar.gz -C /opt && \
	ln -s /opt/apache-ant-1.10.13 /opt/ant && \
	sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment' && \
	ln -s /opt/ant/bin/ant /usr/bin/ant && \
    wget https://dlcdn.apache.org//ant/ivy/2.5.2/apache-ivy-2.5.2-bin.tar.gz && \
	tar xvfvz apache-ivy-2.5.2-bin.tar.gz -C /opt/ant/lib && \
    wget https://dlcdn.apache.org//commons/lang/binaries/commons-lang3-3.14.0-bin.tar.gz && \
	tar xvfvz commons-lang3-3.14.0-bin.tar.gz  -C /opt/ant/lib && \
    git clone https://github.com/apache/freemarker && \
    cd freemarker && \
    git checkout $PACKAGE_VERSION && \
    ant download-ivy && \
    ant

CMD ["/bin/bash"]