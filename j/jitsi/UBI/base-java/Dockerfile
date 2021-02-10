ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/rhel_base

RUN	\
	mkdir -p /usr/share/man/man1 && \
	yum update -y && \
	yum install -y java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le && \
        ln -s /usr/bin/bash /bin/bash

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.275.b01-1.el8_3.ppc64le
