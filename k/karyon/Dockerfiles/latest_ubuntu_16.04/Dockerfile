FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin

RUN apt-get update && \
        apt-get install -y git gradle && \
        git clone https://github.com/Netflix/karyon && \
        cd karyon && ./buildViaTravis.sh && ./installViaTravis.sh && \
        apt-get purge -y git gradle && \
        apt-get autoremove -y

WORKDIR /karyon

ENTRYPOINT ["/bin/bash"]

