FROM  openjdk:8
MAINTAINER "Sanchal Singh <sanchals@us.ibm.com>"
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y git && \
    git clone https://github.com/Netflix/netflix-commons.git && \
    cd netflix-commons && git checkout v0.3.0  && \
    ./gradlew && \
    ./gradlew test && \
    apt-get remove --purge -y git && \
    apt -y autoremove

CMD ["/bin/bash"]
