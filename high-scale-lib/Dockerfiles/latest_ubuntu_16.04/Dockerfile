FROM openjdk:8
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get -y install git wget maven && \
    git clone https://github.com/stephenc/high-scale-lib.git && \
    cd high-scale-lib && \
    mvn clean install && \
    apt-get remove --purge -y git wget maven && \
    apt-get autoremove -y

CMD ["/bin/bash"]
