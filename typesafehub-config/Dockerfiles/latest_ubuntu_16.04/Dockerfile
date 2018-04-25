FROM openjdk:8
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y git apt-transport-https && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
    apt-get update && \
    apt-get install -y sbt && \
    git clone https://github.com/typesafehub/config && \
    cd config && \
    sbt test && \
    apt-get remove --purge -y git apt-transport-https && \
    apt-get autoremove -y

CMD ["/bin/bash"]
