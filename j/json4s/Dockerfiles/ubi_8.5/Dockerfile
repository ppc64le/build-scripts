FROM registry.access.redhat.com/ubi8:8.5 

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.362.b09-2.el8_7.ppc64le
ENV PATH=$JAVA_HOME/bin:$PATH
ENV TZ=Australia/Canberra
ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=v4.1.0-M2

RUN yum update -y && \
	yum install -y curl git java-1.8.0-openjdk-devel nodejs nodejs-devel clang wget tar && \
	rm -f /etc/yum.repos.d/bintray-rpm.repo && \
	curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
	mv sbt-rpm.repo /etc/yum.repos.d/ && \
	yum install -y sbt && \
	cd $HOME_DIR && \
	wget https://github.com/lampepfl/dotty/releases/download/3.2.1/scala3-3.2.1.tar.gz && \
	tar -xvf scala3-3.2.1.tar.gz && \
	export PATH=$HOME_DIR/scala3-3.2.1/bin:$PATH && \
	cd $HOME_DIR && \
    git clone https://github.com/json4s/json4s && \
    cd json4s && \
    git checkout $PACKAGE_VERSION && \
    sbt compile && \
	sbt test

CMD ["/bin/bash"]