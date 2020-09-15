FROM openjdk:8

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y git build-essential gradle g++ ant wget \
        software-properties-common openjdk-8-jdk openjdk-8-jre && \
    git clone https://github.com/ReactiveX/RxJava && \
    cd RxJava && ./gradlew assemble && \
    apt-get remove --purge -y git build-essential g++ ant wget \
        software-properties-common && apt-get autoremove -y

CMD ["/bin/bash"]
