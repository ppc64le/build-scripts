FROM ppc64le/openjdk:openjdk-8-jdk
MAINTAINER Yugandha Deshpande <yugandha@us.ibm.com>

ENV GEODE_VERSION "rel/v1.2.1"

RUN apt-get update && \
    apt-get install git -y && \
    git clone https://github.com/apache/incubator-geode.git --branch=${GEODE_VERSION} && \
    cd incubator-geode \
    && ./gradlew build -Dskip.tests=true -xjavadoc \ 
    && ls /incubator-geode | grep -v geode-assembly | xargs rm -rf \
    && rm -rf /root/.gradle/ \
    && rm -rf /incubator-geode/geode-assembly/build/distributions/ \
    && rm -rf /usr/share/locale/* \
    && apt-get purge git -y && apt-get autoremove -y

ENV GEODE_HOME /incubator-geode/geode-assembly/build/install/apache-geode 
ENV PATH $PATH:$GEODE_HOME/bin 
EXPOSE  8080 10334 40404 1099 7070
CMD ["gfsh"]


