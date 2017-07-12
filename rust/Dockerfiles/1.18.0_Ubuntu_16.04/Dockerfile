FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y wget && \
	wget https://static.rust-lang.org/dist/rust-1.18.0-powerpc64le-unknown-linux-gnu.tar.gz && \
	tar -zxvf rust-1.18.0-powerpc64le-unknown-linux-gnu.tar.gz && \
	cd rust-1.18.0-powerpc64le-unknown-linux-gnu && \
	sh install.sh && \
	rm -rf rust-1.18.0-powerpc64le-unknown-linux-gnu.tar.gz && \
	rm -rf rust-1.18.0-powerpc64le-unknown-linux-gnu && \
	apt-get purge -y wget && apt-get -y autoremove

CMD ["rustc", "--help"]
