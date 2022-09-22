#!/bin/bash

# This Dockerfile was generated from templates/Dockerfile.j2
FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION=v8.4.2

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y procps git make unzip tar ruby gcc-c++ java-1.8.0-openjdk-devel wget gzip procps shadow-utils zip shadow-utils file java-11-openjdk-devel which sudo && \
    yum clean all

RUN wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.tar.gz && \
	sudo tar xvfvz apache-ant-1.10.12-bin.tar.gz  -C /opt && \
	sudo ln -s /opt/apache-ant-1.10.12 /opt/ant && \
	sudo sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment' && \
	sudo ln -s /opt/ant/bin/ant /usr/bin/ant
	
# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir /usr/share/logstash --no-create-home \
      logstash

RUN wget https://github.com/jnr/jffi/archive/jffi-1.2.18.zip \
	&& unzip -u jffi-1.2.18.zip && cd jffi-jffi-1.2.18 \
	&& ant 
RUN yum update -y && yum install -y git make unzip tar ruby gcc-c++  wget gzip procps shadow-utils zip which sudo yum-utils; \
	wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.1%2B10/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz; \
	tar -C /usr/local -xzf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz; \
	export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"; \
	export JAVA_HOME=/usr/local/jdk-18.0.1+10/; \
	export PATH=$PATH:/usr/local/jdk-18.0.1+10/bin; \
	sudo ln -sf /usr/local/jdk-18.0.1+10/bin/java /usr/bin/; \
	rm -f OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz; \
	yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/; \
	yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/; \
	yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/; \
	wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official; \
	mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.; \
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official; \
	curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -; \
	curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -; \
	curl -sSL https://get.rvm.io | bash -s stable --ruby; \
	source /etc/profile.d/rvm.sh; \
	source /usr/local/rvm/scripts/rvm; \
	gem install rake; \
	gem install bundler; \
	bash -c 'rvm install "jruby-9.3.4.0"'; \
	git clone https://github.com/elastic/logstash.git; \
	cd logstash; \
	git checkout $PACKAGE_VERSION; \
	sed -i '2d' ./rakelib/artifacts.rake; \
	rake bootstrap; \
	rake plugin:install-default 
	
RUN mv /logstash /usr/share/logstash && \
    chown --recursive logstash:logstash /usr/share/logstash/ && \
    chown -R logstash:root /usr/share/logstash && \
    chmod -R g=u /usr/share/logstash && \
    find /usr/share/logstash -type d -exec chmod g+s {} \; && \
    ln -s /usr/share/logstash /opt/logstash &&\
    sync && \
    sync && \
    cd ${STARTDIR}

WORKDIR /usr/share/logstash

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.

COPY config/pipelines.yml config/pipelines.yml
COPY config/logstash-full.yml config/logstash.yml
COPY config/log4j2.properties config/
COPY pipeline/default.conf pipeline/logstash.conf
RUN chown --recursive logstash:root config/ pipeline/

# Place the startup wrapper script.
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER 1000

COPY env2yaml/env2yaml /usr/local/bin/

EXPOSE 9600 5044

RUN file /usr/local/bin/docker-entrypoint
RUN cat /usr/local/bin/docker-entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/bin/bash"]