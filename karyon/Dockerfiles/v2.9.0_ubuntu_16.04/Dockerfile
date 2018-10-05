FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"
RUN apt-get -y update && \
    git clone https://github.com/Netflix/karyon --branch=v2.9.0 && \
    cd karyon \
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el  && \
    export JRE_HOME=${JAVA_HOME}/jre  && \
    export PATH=${JAVA_HOME}/bin:$PATH  && \
    ./buildViaTravis.sh  && \
    ./installViaTravis.sh

