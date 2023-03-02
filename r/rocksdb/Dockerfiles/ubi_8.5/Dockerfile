FROM registry.access.redhat.com/ubi8

ENV ROCKSDB_VERSION 7.8.3

RUN yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake && \
		yum install -y sudo && \
		sudo yum install -y zlib zlib-devel bzip2 bzip2-devel lz4-devel libasan wget 
		
RUN wget https://github.com/facebook/zstd/archive/v1.1.3.tar.gz && \
		mv v1.1.3.tar.gz zstd-1.1.3.tar.gz && \
		tar zxvf zstd-1.1.3.tar.gz && \
		cd zstd-1.1.3 && \
		make && sudo make install && \
		cd ..

RUN wget https://github.com/facebook/rocksdb/archive/refs/tags/v${ROCKSDB_VERSION}.tar.gz && \
		tar xf v${ROCKSDB_VERSION}.tar.gz && \
		cd rocksdb-${ROCKSDB_VERSION} && \
		make install-shared && \
		cd / && rm -rf v${ROCKSDB_VERSION}.tar.gz && rm -rf rocksdb-${ROCKSDB_VERSION}
		

CMD ["/bin/bash"]