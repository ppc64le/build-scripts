FROM registry.access.redhat.com/ubi8:8.5 

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.352.b08-2.el8_7.ppc64le
ENV PATH $PATH:$JAVA_HOME/bin
ENV TZ Australia/Canberra

ARG PACKAGE_VERSION v4.1.0-M2

RUN yum update -y && \
	yum install -y curl git java-1.8.0-openjdk-devel nodejs nodejs-devel clang && \
	rm -f /etc/yum.repos.d/bintray-rpm.repo && \
	curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
	mv sbt-rpm.repo /etc/yum.repos.d/ && \
	yum install -y sbt && \
    git clone https://github.com/json4s/json4s json4s/json4s && \
    cd json4s/json4s && \
    git remote update && \
    git fetch && \
    git checkout -qf $PACKAGE_VERSION && \
    sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test

CMD ["/bin/bash"]