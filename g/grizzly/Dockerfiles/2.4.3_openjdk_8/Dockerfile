FROM openjdk:8
MAINTAINER "vibhuti Sawant <vibhuti.Sawant@ibm.com>"

RUN apt-get update \
        && apt-get install -y maven \
        && git clone https://github.com/javaee/grizzly \
        && cd grizzly \
        && git checkout 2_4_3 \
        && mvn install

ENV CLASSPATH /grizzly/modules/grizzly/target/grizzly-framework-2.4.3.jar:.
EXPOSE 8080
CMD ["/bin/bash"]

