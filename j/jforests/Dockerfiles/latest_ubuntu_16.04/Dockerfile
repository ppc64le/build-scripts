FROM openjdk:8
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

ENV CLASSPATH /jforests/realeases/jforests-0.0.1.jar:jforests-0.2.jar:jforests-0.3.jar:jforests-0.4.jar:jforests-0.5.jar:.

RUN apt-get update -y \
 && apt-get -y install maven \
 && git clone https://github.com/yasserg/jforests \
 && cd jforests/jforests/ \
 && mvn compile \
 && mvn test \
 && apt-get purge --auto-remove maven -y

CMD ["/bin/bash"]
