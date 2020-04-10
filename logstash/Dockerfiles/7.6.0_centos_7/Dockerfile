#!/bin/bash

# This Dockerfile was generated from templates/Dockerfile.j2
FROM centos:7

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y procps git make unzip tar ant ruby gcc-c++ java-1.8.0-openjdk-devel wget gzip procps shadow-utils zip shadow-utils file java-11-openjdk-devel which && \
    yum clean all

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir /usr/share/logstash --no-create-home \
      logstash

RUN wget https://github.com/jnr/jffi/archive/jffi-1.2.18.zip \
	&& unzip -u jffi-1.2.18.zip && cd jffi-jffi-1.2.18 \
	&& ant 

RUN cd / && curl -Lo - https://artifacts.elastic.co/downloads/logstash/logstash-7.6.0.tar.gz | \
    tar zxf - -C /usr/share && \
    mv /usr/share/logstash-7.6.0 /usr/share/logstash && \
    chown --recursive logstash:logstash /usr/share/logstash/ && \
    chown -R logstash:root /usr/share/logstash && \
    chmod -R g=u /usr/share/logstash && \
    find /usr/share/logstash -type d -exec chmod g+s {} \; && \
    ln -s /usr/share/logstash /opt/logstash &&\
    # patch from https://github.com/mew2057/CAST/blob/6c7f7d514b7af3c512635ec145aa829c535467dc/csm_big_data/config-scripts/logstashFixupScript.sh 
    STARTDIR=/usr/share/logstash &&  JARDIR="${STARTDIR}/logstash-core/lib/jars" && JAR="jruby-complete-9.2.9.0.jar" && \
    JRUBYDIR="${JAR}-dir" && PLATDIR="META-INF/jruby.home/lib/ruby/stdlib/ffi/platform/powerpc64le-linux" && \
    cd ${JARDIR} && \
    unzip -d ${JRUBYDIR} ${JAR} && \
    cd "${JRUBYDIR}/${PLATDIR}" && \
    cp -n types.conf platform.conf && \
    cd "${JARDIR}/${JRUBYDIR}" && \
    zip -r jruby-complete-9.2.9.0.jar * && \
    mv  -f jruby-complete-9.2.9.0.jar .. && \
    cd ${JARDIR} && \
    rm -rf ${JRUBYDIR} && \
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

# Ensure Logstash gets a UTF-8 locale by default.
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'

# Place the startup wrapper script.
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER 1000

COPY env2yaml/env2yaml /usr/local/bin/

EXPOSE 9600 5044

LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.name="logstash" \
  org.label-schema.version="7.6.1" \
  org.label-schema.url="https://www.elastic.co/products/logstash" \
  org.label-schema.vcs-url="https://github.com/elastic/logstash" \
license="Elastic License"

RUN file /usr/local/bin/docker-entrypoint
RUN cat /usr/local/bin/docker-entrypoint
#RUN find / -name libjffi
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
#CMD ["bin/bash"]
