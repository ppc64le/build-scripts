FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-ppc64el"
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=en_US.UTF-8"
ENV PATH=$JAVA_HOME/bin:$PATH

RUN apt-get update -y && \
    apt-get install -y git gcc ruby ant maven couchdb-bin g++ make \
    openjdk-8-jre-headless openjdk-8-jdk autoconf golang-go libffi6 \
    libffi-dev && \
    cd /tmp && git clone https://github.com/java-native-access/jna && \
    mkdir -p /tmp/jna/build/native-linux-ppc64le/libffi/.libs && \
    cd jna && \
    git checkout 4.1.0 && \
    ln -s /usr/lib/powerpc64le-linux-gnu/libffi.a /tmp/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a && \
    ant test || true && \
    ant test-platform || true && \
    ant dist || true && \
    ln -s /tmp/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so && \
    cd && \
    git clone https://github.com/Netflix/eureka.git eureka && \
    cd ~/eureka/eureka-client && \
    ../gradlew && \
    ../gradlew assemble && \
    apt-get remove --purge -y git gcc ruby ant maven g++ make autoconf && \
    apt-get autoremove -y

CMD ["/bin/bash"]
