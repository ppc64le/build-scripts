FROM  openjdk:8
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y build-essential wget git maven && \
    git clone https://github.com/ronmamo/reflections && \
    cd reflections && \
    mvn dependency:list -DexcludeTransitive; mvn -DskipTests package && \
    mvn test -fn && \
    apt-get remove --purge -y wget git maven && \
    apt -y autoremove

CMD ["/bin/bash"]
