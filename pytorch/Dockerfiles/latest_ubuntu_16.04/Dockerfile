FROM nvidia/cuda-ppc64le:9.0-cudnn7-devel-ubuntu16.04

ENV username=pytorch
ENV python_version=3
ENV git_commit=HEAD
#ENV branch=master
ENV branch=22fe542b8e99679f44386a9327b6f11dde336b34

RUN apt-get update && apt-get install -y --no-install-recommends \
	git sudo

RUN adduser --disabled-password --gecos "" $username
RUN echo "pytorch ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $username
	
RUN cd /home/$username && git config --global http.sslVerify false && \
	git clone https://github.com/avmgithub/pytorch_builder.git && \
	cd pytorch_builder && \
	chmod +x build_nimbix.sh && \
	./build_nimbix.sh  pytorch $git_commit $branch foo $python_version LINUX && \
        sudo apt-get purge -y gfortran
