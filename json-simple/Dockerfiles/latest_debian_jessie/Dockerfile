FROM ppc64le/openjdk:8-jdk

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin

RUN apt-get update && \
        apt-get install -y git wget maven && \
        git clone https://github.com/fangyidong/json-simple && \
        cd json-simple && mvn install && \
        apt-get purge -y git maven && \
        apt-get autoremove -y

WORKDIR /json-simple

ENTRYPOINT ["/bin/bash"]

