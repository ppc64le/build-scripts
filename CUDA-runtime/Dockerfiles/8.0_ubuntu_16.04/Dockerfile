FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV PATH /usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:$LD_LIBRARY_PATH

RUN apt-get update -y && \
	apt-get install -y make wget build-essential libncurses5 libncurses5-dev \
		gcc-4.8 g++-4.8 linux-image-generic linux-headers-generic && \
	wget https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda-repo-ubuntu1604-8-0-local_8.0.44-1_ppc64el-deb && \
	dpkg -i cuda-repo-ubuntu1604-8-0-local_8.0.44-1_ppc64el-deb && \
	apt-get update -y && apt-get install -y cuda && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10 && \
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10 && \
	/usr/local/cuda/bin/cuda-install-samples-8.0.sh ~ && \
	cd ~/NVIDIA_CUDA-8.0_Samples/0_Simple/vectorAdd && make && \
	apt-get purge -y make wget build-essential libncurses5-dev && \
	apt-get -y autoremove && \
	rm -rf /cuda-repo-ubuntu1604-8-0-local_8.0.44-1_ppc64el-deb

CMD ["/bin/bash"]
