FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y apt-transport-https && \
    touch /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
    apt-get update -y && \
    apt-get install -y build-essential dirmngr bc sbt \
        openjdk-8-jdk openjdk-8-jre && \
    git clone https://github.com/ReactiveX/RxScala && \
    cd RxScala && sbt compile && sbt test && \
    apt-get remove --purge -y build-essential dirmngr bc \
        apt-transport-https && \
    apt-get autoremove -y

CMD ["/bin/bash"]
