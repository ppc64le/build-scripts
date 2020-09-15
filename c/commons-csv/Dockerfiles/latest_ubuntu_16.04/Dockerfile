FROM openjdk:8

MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV CLASSPATH /commons-csv/target/commons-csv-1.6-SNAPSHOT.jar:.

RUN apt-get update -y \
  && apt-get install -y gcc make maven \
  && git clone https://github.com/apache/commons-csv \
  && cd commons-csv \
  && mvn dependency:list -DexcludeTransitive; mvn -DskipTests package \
  && mvn test -fn \
  && apt-get purge --auto-remove gcc make maven -y 

CMD ["/bin/bash"]
