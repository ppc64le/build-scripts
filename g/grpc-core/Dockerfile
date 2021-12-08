#
# This dockerfile will create a base image that can be used to build "grpc-core"
# https://github.com/grpc/grpc-java/tree/master/core
#
# The standard name for this image is localhost/grpc-core-base
#

# base image
FROM registry.access.redhat.com/ubi8/ubi-minimal
MAINTAINER "Pratham Murkute <prathamm@us.ibm.com>"

# environment variables
ENV GRADLE_VERSION="6.2.2"
ENV GRADLE_HOME="/usr/local/gradle"
ENV JAVA_HOME=""

# utilities
RUN microdnf install -y git wget curl tar unzip nano vim make dos2unix tree

# java
RUN microdnf install -y java java-devel && \
	which java && \
	ls /usr/lib/jvm/ && \
	export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') && \
	echo "JAVA_HOME is $JAVA_HOME" && \
	export PATH=$PATH:$JAVA_HOME/bin

# gradle
RUN wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
	mkdir -p /usr/local/gradle && \
	unzip -d /usr/local/gradle gradle-$GRADLE_VERSION-bin.zip && \
	ls usr/local/gradle/gradle-$GRADLE_VERSION/ && \
	rm gradle-$GRADLE_VERSION-bin.zip && \
	export GRADLE_HOME=/usr/local/gradle && \
	export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') && \
	export PATH=$PATH:$GRADLE_HOME/gradle-$GRADLE_VERSION/bin

# path
ENV PATH=$PATH:$JAVA_HOME/bin:$GRADLE_HOME/gradle-$GRADLE_VERSION/bin

# copy script
RUN mkdir -p /workspace
COPY ./grpc-core.sh /workspace

# command
CMD ["bash"]
