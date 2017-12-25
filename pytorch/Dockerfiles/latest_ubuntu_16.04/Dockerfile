FROM nvidia/cuda-ppc64le:8.0-cudnn6-devel-ubuntu16.04 

RUN apt-get update && apt-get install -y --no-install-recommends \
	git sudo
	
RUN git config --global http.sslVerify false && \
	git clone https://github.com/avmgithub/pytorch_builder.git && \
	cd pytorch_builder && \
	chmod +x build_nimbix.sh && \
	./build_nimbix.sh  pytorch HEAD master foo 3 LINUX && \
	apt-get purge -y git sudo automake autoconf gfortran curl
