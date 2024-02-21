FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y git wget curl unzip make gcc gcc-c++ file java-11-openjdk java-11-openjdk-devel cmake libstdc++-static

RUN curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
    mv sbt-rpm.repo /etc/yum.repos.d/ && \
    yum -y install sbt
 
RUN cd $SOURCE_DIR && \
    git clone https://github.com/lightbend-labs/scala-logging && \
    cd scala-logging && \
    git checkout v3.9.5 && \
    sbt compile 

CMD ["bash"]

