FROM openjdk:8
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

RUN apt-get update -y && \
    apt-get install -y git ant gradle libjna-java locales \
        gcc g++ make automake libffi-dev build-essential && \
    cp /usr/share/java/jna.jar /usr/lib/jvm/java-8-openjdk-ppc64el/jre/lib/ext && \
    cd /tmp && git clone https://github.com/java-native-access/jna && \
    mkdir -p /tmp/jna/build/native-linux-ppc64le/libffi/.libs && \
    cd jna && git checkout 4.1.0 && \
    ln -s /usr/lib/powerpc64le-linux-gnu/libffi.a /tmp/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a && \
    (ant test || true) && (ant test-platform || true) && (ant dist || true) && \
    ln -s /tmp/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so && \
    cd && \
    git clone https://github.com/Netflix/ribbon && \
    cd ribbon && \
    ./gradlew build && \
    apt-get remove --purge -y git ant gcc g++ make automake \
        libffi-dev build-essential && \
    apt-get autoremove -y

CMD ["/bin/bash"]
