FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION="OTP-25.0"

RUN yum install -y sudo git make unzip tar gcc-c++ gcc clang ncurses ncurses-devel sed java && \
	git clone https://github.com/erlang/otp.git && \
	cd otp && \
	git checkout $PACKAGE_VERSION && \
	./configure && \
	make && \
	make install && \
    export ERL_TOP=$PWD && \
    export PATH=$PATH:$ERL_TOP/bin 

CMD ["erl"]