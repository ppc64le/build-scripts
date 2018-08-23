FROM ppc64le/ubuntu:16.04

RUN apt-get update -y && \
        apt-get install -y git libtool libtool-bin automake build-essential && \
        git clone https://github.com/bagder/c-ares.git && \
        cd c-ares && ./buildconf && ./configure && make && make install && \
	./adig www.google.com && ./acountry www.google.com && ./ahost www.google.com \
        cd test && make && \
	./arestest -4 -v --gtest_filter="-*Container*" && \
	./fuzzcheck.sh && \
	./dnsdump  fuzzinput/answer_a fuzzinput/answer_aaaa && \
        apt-get purge -y git build-essential libtool libtool-bin automake && apt-get autoremove -y

WORKDIR /c-ares

CMD ["/bin/bash"]
