FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y git gcc wget make python39-devel.ppc64le tar curl java-11-openjdk-devel 

RUN curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
    mv sbt-rpm.repo /etc/yum.repos.d/ && \
    yum -y install sbt


    
RUN cd $SOURCE_DIR && \
    git clone https://github.com/codingwell/scala-guice && \
    cd scala-guice && \
    git checkout v5.1.1 && \
    sbt compile 

CMD ["bash"]

