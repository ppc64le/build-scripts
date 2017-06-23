FROM ppc64le/ubuntu:16.04

RUN apt-get update -y && \
        apt-get install -y git libtool libtool-bin automake build-essential && \
        git clone https://github.com/bagder/c-ares.git && \
        cd c-ares && ./buildconf && ./configure && make && \
        cd test && make  && ./arestest && \
        apt-get purge -y git build-essential libtool libtool-bin automake && apt-get autoremove -y

WORKDIR /c-ares

CMD ["/bin/bash"]
