FROM openjdk:8
MAINTAINER "Jay Joshi<joshija@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin
ENV MONGO_REPO="http://repo.mongodb.com/apt/ubuntu"
ENV REPO_TYPE="precise/mongodb-enterprise/2.6 multiverse"
ENV SOURCES_LOC="/etc/apt/sources.list.d/mongodb-enterprise.list"
ENV KEY_SERVER="hkp://keyserver.ubuntu.com:80"
ENV MONGOD_PARAMS="--setParameter=enableTestCommands=1"
ENV MONGOD_OPTS="--dbpath ./data --fork --logpath mongod.log ${MONGOD_PARAMS}"

RUN apt-get update -y && \
    apt-get install git -y autoconf libtool automake build-essential \
        mono-devel gettext libtool-bin dirmngr wget \
        tar ca-certificates-java && \
    update-ca-certificates -f && \
    apt-key adv --keyserver ${KEY_SERVER} --recv 7F0CEB10 && \
    echo "deb ${MONGO_REPO} ${REPO_TYPE}" | tee ${SOURCES_LOC} && \
    git clone https://github.com/mongodb/mongo-java-driver.git && \
    cd mongo-java-driver && \
    git checkout r3.2.0 && \
    ./gradlew assemble -x javadoc && \
    apt-get purge -y autoconf automake mono-devel gettext build-essential \
        wget dirmngr libtool-bin libtool && apt-get autoremove -y

CMD ["/bin/bash"]
