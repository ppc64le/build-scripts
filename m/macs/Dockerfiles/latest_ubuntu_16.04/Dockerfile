FROM python:3
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV PATH $PATH:/root/anaconda2/bin/
RUN apt-get update -y \
  && apt-get install build-essential wget git -y \
  && wget https://repo.continuum.io/archive/Anaconda2-4.4.0-Linux-ppc64le.sh \
  && bash Anaconda2-4.4.0-Linux-ppc64le.sh -b \
  && export PATH=$HOME/anaconda2/bin:$HOME/anaconda2/$PATH \
  && conda install libgfortran -y \
  && git clone https://github.com/taoliu/MACS.git \
  && cd MACS \
  && conda install numpy \
  && python setup_w_cython.py install \
  && apt-get purge --auto-remove git wget build-essential -y

CMD ["/bin/bash"]
