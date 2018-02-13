FROM nvidia/cuda-ppc64le:9.0-cudnn7-devel-ubuntu16.04

RUN apt-get update && apt-get install -y --no-install-recommends \
	git sudo

RUN adduser --disabled-password --gecos "" pytorch
RUN echo "pytorch ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER pytorch
	
RUN cd /home/pytorch && git config --global http.sslVerify false && \
	git clone https://github.com/avmgithub/pytorch_builder.git && \
	cd pytorch_builder && \
	chmod +x build_nimbix.sh && \
	./build_nimbix.sh  pytorch HEAD master foo 3 LINUX && \
        sudo apt-get purge -y gfortran
