FROM ubuntu:18.04

# Owner of a docker file
# email : Meghali Dhoble <dhoblem@us.ibm.com>
MAINTAINER Meghali Dhoble

RUN apt-get update \
    && apt-get install -y make gcc autoconf automake \
    		git python scons g++ cmake \
    && git clone https://github.com/google/double-conversion.git \
    && cd double-conversion \
    && make \
    && make test \
    && scons install \
    && cmake . -DBUILD_TESTING=ON \
    && make \
    && test/cctest/cctest --list | tr -d '<' | xargs test/cctest/cctest \
    && apt-get purge -y make gcc autoconf automake scons g++ cmake && apt-get -y autoremove

CMD ["/bin/bash"]

