FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y wget git zip libjna-java openjdk-8-jdk openjdk-8-jre && \
    cp /usr/share/java/jna.jar $JAVA_HOME/jre/lib/ext && \
    git clone https://github.com/Netflix/governator.git && \
    cd governator && ./gradlew && \
    apt-get remove --purge -y wget git zip && \
    apt-get autoremove -y

CMD ["/bin/bash"]
