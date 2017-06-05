FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y \
        && apt-get install -y build-essential git ant junit libcppunit-dev \
        libcppunit-doc libhamcrest-java libhamcrest-java-doc patch libtool \
        make autoconf automake \

        # Download, build and install Apache ZooKeeper (Branch - 3.5)
        && git clone -b branch-3.5 https://github.com/apache/zookeeper \

        # Set work directory to Apache ZooKeeper
        && cd zookeeper \

        # Build CPP unit test
        && ant compile_jute \
        && cd src/c \
        && ACLOCAL="aclocal -I /usr/share/aclocal" autoreconf -if \
        && ./configure && make && make install \
        && make distclean \
        && cd /zookeeper/ \

        # Build Apache ZooKeeper source code
        && ant jar \

        # Copy default config file
        && cp /zookeeper/conf/zoo_sample.cfg /zookeeper/conf/zoo.cfg \

        && apt-get purge -y build-essential git ant junit libcppunit-dev \
        libcppunit-doc libhamcrest-java libhamcrest-java-doc patch libtool \
        make autoconf automake \

        && apt-get -y autoremove

WORKDIR /zookeeper

# Expose ports for Apache ZooKeeper
EXPOSE 2181 10524

# Start Apache ZooKeeper and tail the log file
CMD bin/zkServer.sh start && HOST=`hostname` && tail -f logs/zookeeper--server-$HOST.out

