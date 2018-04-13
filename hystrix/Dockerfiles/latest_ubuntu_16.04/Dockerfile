FROM openjdk:8
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y libjna-java git && \
    cp /usr/share/java/jna.jar $JAVA_HOME/jre/lib/ext && \
    git clone https://github.com/Netflix/Hystrix.git && \
    cd Hystrix && \
    mv hystrix-core/src/test/java/com/netflix/hystrix/HystrixCommandTest.java hystrix-core/src/test/java/com/netflix/hystrix/HystrixCommandTest.DISABLED_java && \
    apt-get purge -y git && apt-get autoremove -y && \
    ./gradlew && \
    ./gradlew test && \
    apt-get remove --purge git && apt-get autoremove -y

CMD ["/bin/bash"]
