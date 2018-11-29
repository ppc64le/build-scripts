FROM nvidia/cuda-ppc64le:9.2-cudnn7-devel-ubuntu16.04

ENV username=pytorch
ENV python_version=3
ENV git_commit=HEAD
ENV branch=v0.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git sudo && adduser --disabled-password --gecos "" $username
RUN echo "pytorch ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $username

RUN cd /home/$username && git config --global http.sslVerify false && \
        git clone https://github.com/avmgithub/pytorch_builder.git && \
        cd pytorch_builder && \
        chmod +x build_nimbix.sh && \
        ./build_nimbix.sh  pytorch $git_commit $branch foo $python_version LINUX && \
        cd $HOME && rm -rf ccache/ miniconda.sh pytorch_builder/  && sudo rm -rf /tmp/* && \
        sudo apt-get purge -y libopenblas-dev curl  gfortran automake autoconf asciidoc libcudnn7=7.0.3.11-1+cuda9.0 python python3 --allow-change-held-packages && sudo apt-get -y autoremove

