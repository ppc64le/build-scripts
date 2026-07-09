FROM registry.access.redhat.com/ubi9:9.3 

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
ENV TZ=Australia/Canberra
ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=v4.1.0-M8

RUN yum update -y && \
	yum install -y curl git java-1.8.0-openjdk-devel nodejs clang wget tar --allowerasing && \
	rm -f /etc/yum.repos.d/bintray-rpm.repo && \
	curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
	mv sbt-rpm.repo /etc/yum.repos.d/ && \
	yum install -y sbt && \
	cd $HOME_DIR && \
	wget https://github.com/lampepfl/dotty/releases/download/3.5.2/scala3-3.5.2.tar.gz && \
	tar -xvf scala3-3.5.2.tar.gz && \
	export PATH=$HOME_DIR/scala3-3.5.2/bin:$PATH && \
	cd $HOME_DIR && \
    git clone https://github.com/json4s/json4s && \
    cd json4s && \
    git checkout $PACKAGE_VERSION && \
    sbt package

CMD ["/bin/bash"]