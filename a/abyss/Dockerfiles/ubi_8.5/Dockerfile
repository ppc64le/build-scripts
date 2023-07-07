FROM registry.access.redhat.com/ubi8

ARG PACKAGE_VERSION=2.3.5
ENV PATH /usr/local/abyss/bin:$PATH

RUN yum install -y sudo \
		&& sudo yum update -y \
		&& yum install -y gcc-c++ glibc sqlite libgcc libgomp git make wget autoconf bzip2 

RUN git clone https://github.com/sparsehash/sparsehash.git \
		&& cd sparsehash/ \
		&& ./configure --build=ppc64le-redhat-linux \
		&& make \
		&& sudo make install
		
RUN cd / \
		&& sudo dnf makecache \
		&& sudo dnf install -y automake

RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.4.tar.bz2 \
		&& tar xf openmpi-4.1.4.tar.bz2 \
		&& cd openmpi-4.1.4 \
		&& mkdir build \
		&& cd build \
		&& ../configure --prefix=/usr/local/mpi \
		&& cd /

RUN git clone https://github.com/bcgsc/abyss.git \
		&& cd abyss \
		&& git checkout $PACKAGE_VERSION \
		&& wget http://downloads.sourceforge.net/project/boost/boost/1.56.0/boost_1_56_0.tar.bz2 \
		&& tar jxf boost_1_56_0.tar.bz2 \
		&& ./autogen.sh \
		&& mkdir build \
		&& cd build/ \
		&& ../configure --with-mpi=/usr/local/mpi --prefix=/usr/local/abyss \
		&& make \
		&& make install

ENV TMPDIR /var/tmp
ENV SHELL=/bin/bash
ENTRYPOINT ["abyss-pe"]
CMD ["help"]

