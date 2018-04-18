FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin
ENV SBT_OPTS="-server -Xmx3000M -Xss1M -XX:+UseConcMarkSweepGC -XX:NewRatio=8"
ENV JAVA_OPTS="-Xmx4096m"

RUN apt-get update -y && \
    apt-get install -y dirmngr apt-transport-https && \
    touch /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
    apt-get update -y && \
    apt-get install -y git sbt openjdk-8-jdk openjdk-8-jre python \
        build-essential g++ make ca-certificates-java && \
    update-ca-certificates -f && \
    git clone https://github.com/scalatest/scalatest && \
    cd scalatest && sbt compile && sbt test && \
    apt-get remove --purge -y git dirmngr apt-transport-https \
        build-essential g++ make && \
    apt-get autoremove -y

CMD ["/bin/bash"]
