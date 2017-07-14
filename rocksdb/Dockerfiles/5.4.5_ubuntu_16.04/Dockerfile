FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y curl build-essential && \
	curl -L https://github.com/facebook/rocksdb/archive/v5.4.5.tar.gz -o rocksdb.tar.gz && \
        tar xf rocksdb.tar.gz && \
        cd rocksdb-5.4.5 && \
	make install-shared && \
	cd / && rm -rf v5.4.5.tar.gz && rm -rf rocksdb-5.4.5 && \
	apt-get purge -y curl build-essential && apt-get -y autoremove

CMD ["/bin/bash"]
